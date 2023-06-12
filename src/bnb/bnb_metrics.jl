function time_to_first_candidate(tree::BnBTree)
    nodes = candidate_nodes(tree) 
    if length(nodes) == 0 
        return -1 
    end 
    nodes[1].cplex_info["time"]
end 

function context_count_metrics(tree::BnBTree)::Dict{String, Int}
    contexts_of_interest = [
        "branching",
        "candidate",
        "global_progress",
        "relaxation"
    ]

    dict = Dict([n => Int(0) for n in contexts_of_interest])
    for node in tree.nodes 
        context = node.cb_context_id |> context_id_to_small_name
        if context in contexts_of_interest
            dict[context] += 1 
        end     
    end 

    Dict(["$(n)_node_count" => dict[n] for n in contexts_of_interest])
end 

function time_at_best_solution(tree::BnBTree)
    node = best_candidate_node(tree)
    node.cplex_info["time"]
end 

function objective_before_time(tree::BnBTree, time::Int)
    nodes = candidate_nodes(tree)
    before_time_nodes = filter(n -> n.cplex_info["time"] < time, nodes)
    if length(before_time_nodes) == 0 
        @warn "No feasible nodes before $time."
        return missing
    end
    sort!(before_time_nodes, by=n -> n.cplex_info["best_sol"])
    best_node = before_time_nodes[1]
    best_node.cplex_info["best_sol"]
end

function metrics_before_1hour(tree::BnBTree)
    nodes = candidate_nodes(tree)
    before_1hour_nodes = filter(n -> n.cplex_info["time"] < 3600, nodes)
    if length(before_1hour_nodes) == 0 
        @warn "No feasible nodes before 1 hour."
        return Dict()
    end
    sort!(before_1hour_nodes, by=n -> n.cplex_info["best_sol"])
    best_node = before_1hour_nodes[1]

    times = 60*[10, 20, 30, 40, 60, 70, 80, 90, 100, 110, 120]
    objs = map(times) do time 
        objective_before_time(tree, time)
    end 
    dict_times = Dict([("best_objective_before_$(t)", o) for (t, o) in zip(times, objs)])

    dict_1h = Dict(
        "best_objective_value_before_1hour" => best_node.cplex_info["best_sol"],
        "time_at_best_solution_before_1hour" => best_node.cplex_info["time"],
    )
    return merge([dict_times, dict_1h]...)
end

function metrics_dict(tree::BnBTree)
    d1 = Dict(
        "number_candidates" => tree.number_candidates,
        "node_count" => length(tree.nodes),
        "time_to_first_candidate" =>  time_to_first_candidate(tree),
        "with_solution_node_count" => length(nodes_with_solution(tree)),
        "time_at_best_solution" => time_at_best_solution(tree),
    )
    d2 = context_count_metrics(tree)
    d3 = metrics_before_1hour(tree)
    merge([d1, d2, d3]...)
end         

function get_dataframes(tree::BnBTree)
    if length(tree.nodes) > 0
        tree_dataframes = Dict(
            "solutions" => solutions_to_df(tree),
            "nodes" => to_df_from_dict([node.cplex_info for node in tree.nodes]), 
        )
    else
        tree_dataframes = Dict()
    end
    return tree_dataframes
end