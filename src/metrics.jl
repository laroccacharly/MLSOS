function value(m::MetricType, s::Any)
    if ismissing(get(s.info, name(m), missing))
        try
            value = build(m, s)
            s.info[name(m)] = value
            # update_info!(s, Dict(name(m) => value))
        catch ex  
            @warn ex 
            @warn "Cannot build $m"
            return NaN 
        end 
    end 
    
    return s.info[name(m)]
end 
update_info!(s, info) = nothing 

function build(::PrimalGaps, s::SolverResultsType)
    tree = recover_tree_from_results(s, with_solutions=false)
    nodes = candidate_nodes(tree)
    cplex_results = get_cplex_results(s)
    cplex_objective_value = best_objective_value(cplex_results)

    gaps = Number[1]
    times = Number[0] 
    for index in 1:length(nodes)
        node = nodes[index]
        primal_gap = (best_objective_value(node) - cplex_objective_value)/cplex_objective_value    
        push!(times, get_time(node))
        push!(gaps, primal_gap)
    end 
    return gaps, times 
end 

function get_primal_gap(s::SolverResultsType, time::Number)::Number 
    gaps, times = value(PrimalGaps(), s)
    for index in 1:length(gaps)
        if index+1 >length(gaps)
            next_time = Inf 
        else 
            next_time = times[index+1]
        end 
        if time >= times[index] && time < next_time 
            return gaps[index]
        end 
    end 
end 

function build(::StrictlyBetterRatio, s::SolverResultsType)
    cplex_results = get_cplex_results(s)

    times = 0:1:cplex_results.info["time_to_solve"]
    strictly_better = []
    for t in times 
        cplex_primal_gap = get_primal_gap(cplex_results, t)
        primal_gap = get_primal_gap(s, t)
        push!(strictly_better, primal_gap<cplex_primal_gap)
    end 
    return mean(strictly_better)
end 

function build(::TimeToBetterSolution, s::SolverResultsType)
    tree = recover_tree_from_results(s, with_solutions=false)
    nodes = candidate_nodes(tree)
    cplex_results = get_cplex_results(s)
    cplex_objective_value = best_objective_value(cplex_results)
    time_to_better_solution = Float64(0.0) 
    for node in nodes 
        if node.cplex_info["best_sol"] < cplex_objective_value
            time_to_better_solution = get_time(node) + 0.0
        end 
    end 
    return Float64(time_to_better_solution) 
end 


# from https://doi.org/10.1016/j.orl.2013.08.007 
function build(::PrimalIntegral, s::SolverResultsType)
    tree = get_tree(s)
    nodes = tree.nodes
    nodes = filter(is_objective_value_valid, nodes)
    cplex_results = get_cplex_results(s)
    cplex_objective_value = best_objective_value(cplex_results)
    primal_integral = 0.0

    gaps = Number[1]
    times = Number[0] 
    for index in 1:length(nodes)
        node = nodes[index]
        if index == 1 
            primal_gap = 1
            time_step = get_time(nodes[1]) 
        else 
            prev_node = nodes[index - 1]
            primal_gap = (best_objective_value(prev_node) - cplex_objective_value)/cplex_objective_value    
            time_step =  get_time(node) - get_time(prev_node) 
        end 
        push!(times, get_time(node))
        push!(gaps, primal_gap)
        primal_integral += primal_gap * time_step
    end 
    #@show times
    #@show gaps
    #lineplot(times, gaps, title = "primal integral $s", 
    # xlabel = "candidate_node" , ylabel = "primal gap") |> display  

    primal_integral
end 

function build(::CplexPrimalIntegral, s::SolverResultsType)
    value(PrimalIntegral(), get_cplex_results(s))
end 

function build(::PrimalIntegralRatio, s::SolverResultsType)
    value(PrimalIntegral(), s)/value(CplexPrimalIntegral(), s)
end 

function build(::RuntimeSpeedup, s::SolverResultsType)
    cplex_results = get_cplex_results(s)
    # cplex_results.info["time_to_solve"]/s.info["time_to_solve"]
    time_at_best_solution(get_tree(cplex_results))/time_at_best_solution(get_tree(s))
end 

is_cplex(s::SolverResultsType) = s.info["algorithm"] == "cplex" 
is_cplex(s::SolverResults) = s.algorithm == CPLEXAlgorithm()


function build(::ActionAccuracy, s::SolverResultsType)
    if is_cplex(s)
        return NaN 
    end 
    learner_metrics = load_dataframe(s, "learner_metrics.parquet")
    # @show size(learner_metrics, 1)
    mean(learner_metrics[!, :action_accuracy])
end 

function value(::OptimalityGap, s::SolverResultsType)
    get_optimality_gap(s)
end 

function get_optimality_gap(s::SolverResultsType)
    s.info["gap"]
end 

function build(::RelativeGap, s::SolverResultsType)
    if is_cplex(s)
        return NaN 
    end 
    cplex_results = get_cplex_results(s)
    (best_objective_value(s) - best_objective_value(cplex_results))/best_objective_value(cplex_results)
end 

function build(::TimeToFirstCandidate, s::SolverResultsType)
    tree = recover_tree_from_results(s, with_solutions=false)
    nodes = candidate_nodes(tree) 
    return nodes[1].cplex_info["time"]
end 


# TODO: fix this 
function rename_algorithm(s::String)
    if occursin("n=5", s)
        return "SP(n=5)"
    end 
    if occursin("n=1", s)
        return "SP(n=1)"
    end 
    if occursin("t=0.5", s)
        return "TP(t=0.5)"
    end 
    return s 
end 

function collect_and_save_metrics(dataset; path=experiment_path(), file_name="metrics")
    metrics = collect_metrics(dataset)
    @show metrics
    save_object(metrics, file_name, path)
end
export collect_and_save_metrics


function compute_action_metrics(result::SolverResultsType)
    instance = get_instance(result)
    constraints = get_lazy_constraints(result)
    Dict(
        "action_accuracy" => compute_action_accuracy(instance, constraints)
    )
end 

function compute_action_accuracy(instance::ProblemInstance, constraints::Array{T, 1} where T <: LazyConstraintType)
    if length(constraints) == 0 
        return NaN 
    end 
    predictions = [] 
    targets = []
    acc = [] 
    for constraint in constraints
        object_id = get_object_id(constraint)
        object = get_object(instance, object_id)
        target = get_label(object, get_label_type(instance))
        push!(targets, target)
        push!(predictions, constraint.label)
        push!(acc, target == constraint.label)
    end 
    df = DataFrame("targets" => targets, "predictions" => predictions)
    mean(acc)
end 

function compute_action_accuracy(state::StateType)
    compute_action_accuracy(state.instance, state.lazy_constraints)
end 

