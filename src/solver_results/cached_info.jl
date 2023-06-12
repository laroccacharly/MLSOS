function get_info(r::SolverResultsType, info::CachedInfo)
    if ismissing(get(r.info, name(info), missing))
        r.info[name(info)] = build_info(r, info)
    end 
    
    return r.info[name(info)]
end 

struct EntropyHash <: CachedInfo
end 
name(::EntropyHash) = "entropy_hash"
entropy_hash(r::SolverResultsType) = get_info(r, EntropyHash())

struct OptimalSolutionHash <: CachedInfo
end 
name(::OptimalSolutionHash) = "optimal_solution_hash"
optimal_solution_hash(r::SolverResultsType) = get_info(r, OptimalSolutionHash())


function build_info(results::SolverResultsDF, info::OptimalSolutionHash)
    df = merge_dataframes(results)
    optimal_objective_value = minimum(df[!, :best_sol])
    best_solution = filter(r -> r.best_sol == optimal_objective_value, df) 

    optimal_solution_hash = Dict() # arc id -> consist_id 
    for g in groupby(best_solution, :arc_id)
        arc_id = g[1, :arc_id]
        optimal_solution_hash[arc_id] = g[1, :consist_id]
    end 
    return optimal_solution_hash
end 


function build_info(results::SolverResultsType, info::EntropyHash)
    instance = recover_instance_from_results(results)
    @info "Building entropy hash for instance $(instance)"
    tree = get_tree(results)
    data = [] 
    for node in nodes_with_solution(tree)
        hash = get_solution_hash_for_label_type(node.solution_df, get_label_type_local(instance))
        d = Dict()
        for object in get_objects(instance)
            d[object.id] = get(hash, object.id, 0)
        end 
        push!(data, d)
    end 
    df = to_df_from_dict(data)
    # @show select(df, sort(names(df))[1:min(10, length(names(df)))]) 
    entropy_hash = Dict() # id -> entropy 
    for col_name in names(df)
        key = col_name
        values = Float64[v for v in df[!, col_name]]
        entropy_value = get_entropy(values) 
        entropy_hash[parse(Int, key)] = entropy_value
    end 

    @show entropy_hash
    @show median(values(entropy_hash))
    # histogram(Number[v for v in values(entropy_hash)], title = "Entropy distribution") |> display 
    return entropy_hash
end 
