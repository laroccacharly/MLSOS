function time_vs_gap_plot_data(s::SolverResultsType) 
    tree = get_tree(s)
    cplex_results = get_cplex_results(s)
    cplex_tree = get_tree(cplex_results)
    
    t1, v1 = collect_time_and_objective_value(cplex_results)
    t2, v2 = collect_time_and_objective_value(s)
    cplex_best_objective_value = best_objective_value(s)
    g1 = normalize(v1, cplex_best_objective_value)
    g2 = normalize(v2, cplex_best_objective_value)

    data = [] 
    for index in 1:length(t1)
        push!(data, 
            Dict(
                "algorithm" => "cplex",
                "time" => t1[index], 
                "gap" => g1[index], 
            )
        )
    end 

    for index in 1:length(t2)
        push!(data, 
            Dict(
                "algorithm" => algorithm(s),
                "time" => t2[index], 
                "gap" => g2[index], 
            )
        )
    end 

    df = to_df_from_dict(data)
    @show df 

end 

function normalize(arr, value)
    map(arr) do a 
        (a - value)/value
    end     
end 

function collect_time_and_objective_value(s::SolverResultsType)
    tree = get_tree(s)
    times = []
    objective_values = [] 
    values_seen = Dict()
    for node in tree.nodes 
        if is_objective_value_valid(node)
            current_value = best_objective_value(node)
            seen = get(values_seen, current_value, false)
            if seen
                continue 
            else 
                values_seen[current_value] = true 
                push!(times, get_time(node))
                push!(objective_values, current_value)
            end 
        end 
    end 
    return times, objective_values
end 