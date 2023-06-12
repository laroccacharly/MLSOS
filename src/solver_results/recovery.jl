function recover_tree_from_results!(r::SolverResultsType; with_solutions::Bool=true)
    if !ismissing(get(r.info, "tree", missing))
        return r 
    end 
    tree = BnBTree() 
    node_uuid_to_solutions = Dict() 

    if with_solutions
        try 
            solutions_df = load_solutions_df(r)
            for gdf in groupby(solutions_df, :node_uuid)
                node_uuid = gdf[1, :node_uuid]
                node_uuid_to_solutions[node_uuid] = DataFrame(gdf)  
            end 
        catch e 
            @warn e 
            @warn "Could not load solutions" 
        end
    end 

    node_df = load_nodes_df(r)
    bar = ProgressUnknown("Progress loading tree")

    for (index, row) in enumerate(eachrow(node_df))
        node_uuid = row.node_uuid 
        context_id = context_string_to_id(row.context)
        cplex_info = dfrow_to_dict(row)
        is_candidate::Bool = context_id == CPX_CALLBACKCONTEXT_CANDIDATE
        is_lpp::Bool = context_id == CPX_CALLBACKCONTEXT_RELAXATION
        solution_df = missing 
        if is_candidate || (is_lpp && get_value("load_solution_on_lp_nodes"))
            solution_df = get(node_uuid_to_solutions, node_uuid, missing) 
         end 
         node = BnBNode(node_uuid, context_id, cplex_info, solution_df)
         ProgressMeter.next!(bar; 
         showvalues = [
             (:total_nodes, size(node_df, 1)), 
             (:index, index), 
         ])
         add_node!(tree, node)
    end 
    @info "Recovered tree with $(length(tree.nodes)) nodes" 
    @info "Tree has $(length(nodes_with_solution(tree))) nodes with a solution" 
    r.info["tree"] = tree 
    return r 
end 

function get_tree(s::SolverResultsType)::BnBTree 
    recover_tree_from_results!(s)
    s.info["tree"]
end 

function recover_instance_from_results(results::SolverResultsType)::ProblemInstance
    key = get_key(results)
    @assert !ismissing(key) 
    scenario = key.scenario 
    instance = build_instance!(scenario)
    return instance
end 

function try_set_labels!(instance::ProblemInstance, results::SolverResultsType)
    try 
        set_labels!(instance, results)
    catch e
        @warn e 
        @warn "Could not set labels on instance $(get_id(instance))" 
    end 
end

function recover_instance_from_results!(results::SolverResultsType) 
    if !ismissing(get(results.info, "instance", missing))
        return results 
    end 
    instance = missing 
    
    try 
        instance = recover_instance_from_results(results)
    catch 
        @warn "Could not recover instance from results using default method" 
        problem = get(results.info, "problem_name", "lap")
        if problem == "lpp"
            instance = recover_lpp_from_results(results)
        elseif problem == "lap"
            instance = recover_net_from_results(results)
        else
            @error "Could not recover instance from results" 
        end   
    end

    try_set_labels!(instance, results)
    results.info["instance"] = instance
    return results 
end 

function get_instance(s::SolverResultsType)::ProblemInstance 
    recover_instance_from_results!(s)
    s.info["instance"]
end 

get_benchmarks(r::SolverResultsType) = load_dataframe(r, "benchmarks.parquet")

function load_dataframe(s::SolverResultsType, filename::String)::DataFrame 
    path = get_path(s) * "/" * filename
    read_from_disk(file_storage_protocol(), path)
end 

function load_lazy_constraints_df(s::SolverResultsType)
    try
        load_dataframe(s, "lazy_constraints.parquet")
    catch 
        return DataFrame() 
    end 
end 

function get_lazy_constraints(s::SolverResultsType)
    df = load_lazy_constraints_df(s)
    map(eachrow(df)) do row 
        SingleSolutionConstraint(
            row["node_uuid"], row["object_id"], row["label"], get_label_type(get_instance(s))
        )
    end 
end 

function load_nodes_df(s::SolverResultsType)
    load_dataframe(s, "nodes.parquet")
end 

function load_solutions_df(s::SolverResultsType)
    load_dataframe(s, "solutions.parquet")
end 