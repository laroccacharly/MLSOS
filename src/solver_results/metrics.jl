
 struct FreezingTime <: MetricType 
 end 
 name(::FreezingTime) = "freezing_time"

 function build(::FreezingTime, s::SolverResultsType)
    constraints = get_lazy_constraints(s)
    if length(constraints) == 0 
        return 0.0 
    end
    constraint = constraints[1]
    node_uuid = constraint.node_uuid
    tree = get_tree(s)
    node = find_node(tree, node_uuid)
    return get_time(node)
end 

struct TimeCollectData <: MetricType 
end 
name(::TimeCollectData) = "time_to_collect_data"

function build(::TimeCollectData, s::SolverResultsType)
    df = get_benchmarks(s)
    df[!, :time_to_collect_data] |> sum
end 

struct TimeToRunAlgorithm <: MetricType 
end
name(::TimeToRunAlgorithm) = "time_to_run_algorithm"
function build(::TimeToRunAlgorithm, s::SolverResultsType)
    df = get_benchmarks(s)
    df[!, :time_to_run_algorithm] |> sum
end

struct BnBTreeMetric <: MetricType 
    name::String
end
name(m::BnBTreeMetric) = m.name
function build(m::BnBTreeMetric, s::SolverResultsType)
    tree = get_tree(s)
    metrics = metrics_dict(tree)
    return metrics[m.name]
end

function metrics(::SolverResultsType)
    MetricType[
        #ActionAccuracy(),
        # OptimalityGap(),
        RelativeGap(),
        FreezingTime(), 
        TimeCollectData(), 
        TimeToRunAlgorithm(), 
        BnBTreeMetric("number_candidates"),
        # TimeToFirstCandidate(),
        #PrimalIntegral(),
        #CplexPrimalIntegral(),
        PrimalIntegralRatio(),
        RuntimeSpeedup(), 
        #StrictlyBetterRatio(),
        #TimeToBetterSolution(),
        # NumberCandidates(), 
    ]
end 


function compare_trees(s::SolverResultsType)
    tree = get_tree(s)
    cplex_results = get_cplex_results(s)
    cplex_tree = get_tree(cplex_results)
    info_keys = [
        "simplex_iterations",
        "best_bnd",
        "best_sol",
        "cplex_node_count",
        "number_candidates",
        "node_collected"
    ]
    for key in info_keys
        data = [] 
        for index in get_indexes(cplex_tree)
            cplex_node = get_first_node_at_index(cplex_tree, index)
            if  get_info(cplex_node, "found_sol") != 1 
                continue 
            end 
            try 
                node = get_first_node_at_index(tree, index)
                push!(data, Dict(
                    "index" => index, 
                    "cplex_$key" => get_info(cplex_node, key),
                    "algo_$key" => get_info(node, key)
                ))
            catch
               #  @warn "Skipping index $index." 
            end 
        end 
        df = to_df_from_dict(data)
        sort!(df, :index)
        # ys = [df[!, "cplex_$key"], df[!, "algo_$key"]]
        
        plt = lineplot(df[!, :index], df[!, "cplex_$key"], 
            xlabel = "index" , ylabel = key, name="cplex")
        lineplot!(plt, df[!, :index], df[!, "algo_$key"], name="heuristic") |> display 
        @show key 
        @show df
    end 
end 

function show_candidate(tree::BnBTree, index::Int)
    nodes = candidate_nodes(tree)
    if index > length(nodes)
        @info "No candidates at $index"
        return 
    end 
    
    @show index 
    display(nodes[index].cplex_info)
    @show nodes[index].solution_df 
end 

function compare_candidates(s::SolverResultsType)
    tree = get_tree(s)
    cplex_results = get_cplex_results(s)
    cplex_tree = get_tree(cplex_results)
    cplex_number_candidates = length(candidate_nodes(cplex_tree))
    number_candidates = length(candidate_nodes(tree))

    @show cplex_number_candidates
    @show number_candidates
    @show max_candidate = max(cplex_number_candidates, number_candidates)

    for i in 1:max_candidate
        show_candidate(cplex_tree, i)
        show_candidate(tree, i)
    end 
end 

function compare_instances(s::SolverResultsType)
    cplex_results = get_cplex_results(s)
    instance = get_instance(s)
    cplex_instance = get_instance(cplex_results)
    for (object, cplex_object) in zip(get_objects(instance), get_objects(cplex_instance))
        @show object.id
        @show get_label(object)
        #Base.show(loading_patterns[get_label(object)])
        #Base.show(cplex_object)
        @show get_label(cplex_object)
        #Base.show(loading_patterns[get_label(cplex_object)])

    end 
end 

function show_lazy_constraints(s::SolverResultsType)
    @show load_lazy_constraints_df(s)
end 

function termination_metrics_dict(s::SolverResults)
    typedict(s.metrics)
end 

function termination_metrics_dict(s::SolverResultsType)
    names = ["time_to_solve", "gap", "objective_value", "is_optimal"]
    Dict(name => s.info[name] for name in names)
end 

function total_time_to_collect_data(r::SolverResultsType)
    df = get_benchmarks(r)
    df[!, :time_to_collect_data] |> sum 
end     



function learner_metrics(s::SolverResultsType)
    if algorithm(s) == "cplex"
        return Dict() 
    end 
    load_dataframe(s, "learner_metrics.parquet")
end 

function algorithm_metrics(s::SolverResultsType, ::MIPAlgorithm)
    Dict(
        "fixing_ratio" => get(s.info, "fixing_ratio", 0.0),
        "scoring_type" => get(s.info, "scoring_type", "none"),
        "label_type" => get(s.info, "label_type", "none"),
        "callback_action_type" => get(s.info, "callback_action_type", "none")
    )
end 

function algorithm_metrics(s::SolverResultsType) 
    key = get_key(s)
    algorithm = key.algorithm
    algorithm_metrics(s, algorithm)
end

function relaxation_metrics(s::SolverResultsType)
    instance = get_instance(s)
    relaxation_metrics(s, instance)
end 

function relaxation_metrics(s::SolverResultsType, instance::ProblemInstance)
    # @warn "No relaxation metrics for $(problem_name(instance))"
    return Dict() 
end 

function show_relaxation(s::SolverResultsType)
    tree = get_tree(s)
    node = candidate_nodes(tree)[end]
    for node in nodes_with_solution(tree)
        @show node.cplex_info
        @show node.solution_df
    end 
end 

function algorithm_name(result::SolverResultsType)
    JSON.parse(result.info["algorithm"])["name"]
end 

function try_tree_metrics_dict(s::SolverResultsType)
    try
        metrics_dict(get_tree(s))
    catch 
        return Dict()
    end 
end

function metrics_dict(s::SolverResultsType)
    data = Dict{String, Any}()
    for metric in metrics(s)
        data[name(metric)] = value(metric, s)
    end 
    data = merge(data, termination_metrics_dict(s))
    data = merge(data, metrics_dict(get_instance(s)))
    data = merge(data, try_tree_metrics_dict(s))
    data = merge(data, algorithm_metrics(s))
    data = merge(data, relaxation_metrics(s))
    data = merge(data, compute_action_metrics(s))
    return data 
end 

function compute_metrics(result::SolverResultsType)
    # show_relaxation(result)
    merge(metrics_dict(result), Dict(
        "algorithm" => algorithm(result),
        "algorithm_name" => algorithm_name(result),
        "seed" => get(result.info, "seed", 0),
        "learner" => get(result.info, "learner", "none"), 
        "instance_id" => get_id(result), 
        "problem_name" => problem_name(result), 
        "created_at" => get(result.info, "created_at", missing), 
    ))
end 

function compute_metrics(dataset::DatasetType)
    results = get_results(dataset)
    if has_cplex_dataset(dataset)
        all_results = vcat(results, get_results(dataset.cplex_dataset))
    else 
        all_results = results 
    end 

    # show_lazy_constraints.(results)
    # compare_instances.(results)
    # compare_candidates.(results)
    # show_info(get_tree(result), "cplex_node_id")
    # time_vs_gap_plot_data.(get_results(dataset))

    list = map(all_results) do result 
        compute_metrics(result)
    end 

    metrics = to_df_from_dict(list; json_fallback=true)

    # df = leftjoin(df, compute_gap_vs_speed_up(dataset), on=[:instance_id, :algorithm])
    
    return metrics 
end     

function compute_metrics(dataset::DatasetType, task_id::Int)
    key = get_key_from_task_id(dataset, task_id)
    db = get_db(dataset)
    result = get_result(db, key)
    metrics = compute_metrics(result)
    save_metrics(result, metrics)
end

function compute_missing_metrics(dataset::DatasetType)
    map(get_results(dataset)) do result
        metric = try_load_metrics(result)
        if ismissing(metric)
            metrics = compute_metrics(result)
            save_metrics(result, metrics)
        end 
    end 
end
export compute_missing_metrics

function collect_metrics(dataset::DatasetType)
    all_results = get_results(dataset)
    metrics = map(all_results) do result 
        try_load_metrics(result)
    end
    metrics = filter!(x -> !ismissing(x), metrics)
    # Replace nothing values with NaN in dict 
    metrics = map(metrics) do metric
        for (key, value) in metric
            if value === nothing
                metric[key] = NaN
            end 
        end 
        metric
    end

    return metrics
end
