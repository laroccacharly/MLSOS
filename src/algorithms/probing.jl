mutable struct ProbeAndFreezeAlgorithm <: MIPAlgorithm
    name::String
    probing_time_budget::Int
    fixing_ratio::Float64
    scoring_type::ScoringType
    dataframes::Dict{String, DataFrame}
end 

function ProbeAndFreezeAlgorithm(probing_time_budget::Int, fixing_ratio::Float64)
    ProbeAndFreezeAlgorithm("PNF_$(fixing_ratio)_$(probing_time_budget)", probing_time_budget, fixing_ratio, HistoricalEntropyScore(), Dict())
end

function PNF(fixing_ratio::Float64, probing_time_budget::Int)
    ProbeAndFreezeAlgorithm(probing_time_budget, fixing_ratio)
end 
export PNF 


function solver_params(algo::ProbeAndFreezeAlgorithm)
    return CPLEXParams(;time_limit=cplex_time_limit() - algo.probing_time_budget)
end 

mutable struct ProbingAlgorithm <: MIPAlgorithm
    name::String
    probing_time_budget::Int
end 
ProbingAlgorithm(time_budget::Int) = ProbingAlgorithm("probing", time_budget)

function should_collect_callback_solution(state::StateType, algorithm::ProbingAlgorithm)::Bool
    if state.context_id == CPLEX.CPX_CALLBACKCONTEXT_CANDIDATE || state.context_id == CPLEX.CPX_CALLBACKCONTEXT_RELAXATION
        return true 
    end 
    return false 
end 

function solver_params(algo::ProbingAlgorithm)
    return CPLEXParams(;time_limit=algo.probing_time_budget)
end 


has_scheduler(::ProbeAndFreezeAlgorithm) = false 
has_stats(::ProbeAndFreezeAlgorithm) = false  
has_scheduler(::ProbingAlgorithm) = false 
has_stats(::ProbingAlgorithm) = true  

function add_additional_constraints!(state::PresolveState, algo::ProbeAndFreezeAlgorithm)
    probing_time_budget = algo.probing_time_budget
    probing_algorithm = ProbingAlgorithm(probing_time_budget)
    probing_results, probing_state = build_and_solve_mip!(state.instance, algorithm=probing_algorithm, save_results=false, return_state=true)
    probing_tree = probing_state.tree
    @show probing_results.info 
    learner = OneShotLearner()
    probing_state.info["scoring_type"] = algo.scoring_type
    probing_state.info["fixing_ratio"] = algo.fixing_ratio
    if length(nodes_with_solution(probing_tree)) == 0 
        @warn "No solution found in probing tree"
        @warn "Skipping freezing"
        return state 
    end

    actions = make_actions!(probing_state, learner)     
    # Store the entropy for each object (sos constraint) in the instance 
    fixed_object_ids = [action.constraint.object_id for action in actions]
    data = []
    for object in get_objects(state.instance)
        d = Dict(
            "object_id" => object.id, 
            "entropy" => get_entropy(probing_state, object),
            "fixed" => object.id in fixed_object_ids
        )
        push!(data, d)
    end
    df_entropy = to_df_from_dict(data)
    @show mean([d["entropy"] for d in data])

    probing_tree_metrics = Dict(
        "number_candidates" => probing_tree.number_candidates,
        "node_count" => length(probing_tree.nodes),
        "with_solution_node_count" => length(nodes_with_solution(probing_tree)),
    )
    data = [] 
    for (k, v) in probing_tree_metrics
        d = Dict("metric_name" => k, "value" => v)
        push!(data, d)
    end
    df_tree_metrics = to_df_from_dict(data)
    dataframes = Dict("sos_entropy" => df_entropy, "probing_tree_metrics" => df_tree_metrics) 
    algo.dataframes = dataframes
    for action in actions 
        object = get_object(state.instance, action.constraint.object_id)
        @show get_entropy(probing_state, object)
        for constraint in build_jump_constraints(state, action)
            @show constraint
            JuMP.add_constraint(state.model.model, constraint)
        end 
    end 
    return state 
end 


function format_json(json::Dict, ::ProbeAndFreezeAlgorithm)
    Base.delete!(json, "dataframes")
    return json 
end 


function get_dataframes(a::ProbeAndFreezeAlgorithm) 
    return a.dataframes
end 

function algorithm_callback(state::StateType, algo::ProbeAndFreezeAlgorithm) 
    return state
end 

function algorithm_callback(state::StateType, algo::ProbingAlgorithm) 
    if !is_init(state) 
        init!(state, algo)
        return 
    end 

    if has_stats(algo)
        update_stats!(state)
    end 
end 

function corrected_runtime_speedup(s::SolverResultsType, algo::ProbeAndFreezeAlgorithm)
    speed_up = NaN
    try
        probing_time_budget = algo.probing_time_budget
        cplex_results = get_cplex_results(s)
        speed_up = time_at_best_solution(get_tree(cplex_results))/(time_at_best_solution(get_tree(s)) + Float64(probing_time_budget))
    catch e
        @warn "Could not compute corrected runtime speedup"
        @warn e
    end
    return Dict("corrected_runtime_speedup" => speed_up) 
end

function algorithm_metrics(s::SolverResultsType, algo::ProbeAndFreezeAlgorithm)
    probing_metrics = Dict() 
    try 
        probing_tree_metrics = load_dataframe(s, "probing_tree_metrics.parquet")
        rows = eachrow(probing_tree_metrics)
        probing_metrics = Dict(["probing_$(row.metric_name)" => row.value for row in rows])
    catch e
        @warn "Could not load probing metrics"
        @warn e
    end
    entropy_metrics = Dict()
    try 
        sos_entropy = load_dataframe(s, "sos_entropy.parquet")  #This can be empty if no solution was found in probing
        fixed_rows = filter(row -> row.fixed, eachrow(sos_entropy))
        unfixed_rows = filter(row -> !row.fixed, eachrow(sos_entropy))
        entropy_metrics = Dict(
            "average_entropy" => mean(sos_entropy[!, "entropy"]),
            "average_fixed_entropy" => mean(fixed_rows.entropy),
            "average_unfixed_entropy" => mean(unfixed_rows.entropy),
            "median_entropy" => median(sos_entropy[!, "entropy"]),
        )
    catch e
        @warn "Could not load sos entropy"
        @warn e
    end
    dicts = [
        probing_metrics,
        entropy_metrics,
        corrected_runtime_speedup(s, algo),
    ]
    return merge(dicts...)
end