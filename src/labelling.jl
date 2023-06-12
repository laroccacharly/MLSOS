is_binary(::SolutionStability) = true 

get_label(object::InstanceObjectType)::Number = get_label(object, get_label_type(object))
mip_var_sym(object::InstanceObjectType) = mip_var_sym(get_label_type(object))
get_label_type(instance::ProblemInstance) = get_objects(instance) |> first |> get_label_type
get_target_sym(instance::ProblemInstance)::Symbol = get_label_type(instance) |> get_symbol
get_index_sym(instance::ProblemInstance) = get_label_type(instance) |> get_index_sym

get_label_type(d::DatasetType)::LabelType = get_results(d) |> first |> get_label_type
get_label_type(s::SolverResultsType) = get_instance(s) |> get_label_type

function set_labels!(instance::ProblemInstance, results::SolverResultsType)
    #for label_type in get_all_label_types(instance) 
    @info "Setting labels"
    if !is_cplex(results)
        r = get_cplex_results(results)
    else
        r = results 
    end 
    set_label!(instance, r, get_label_type(instance))
    return instance 
end 

function set_label!(instance::ProblemInstance, results::SolverResultsType, label_type::LabelType)
    for object in get_objects(instance)
        set_label!(object, instance, results, label_type)
    end 
end 

function set_label!(object::InstanceObjectType, instance::ProblemInstance, results::SolverResultsType, label_type::LabelType)
    set_label!(object, label_type, make_label(object, instance, results, label_type))
end 

default_label(::LabelType) = 0 

function make_label(object::InstanceObjectType, instance::ProblemInstance, results::SolverResultsType, label_type::LabelType)
    tree = get_tree(results)
    node = best_candidate_node(tree)
    h = get_solution_hash_for_label_type(node.solution_df, label_type)
    try 
        solution = h[object.id]
        return solution
    catch ex 
        @warn "Cannot collect solution from tree $(algorithm(results))"
        display(h)
        @warn ex 
        return default_label(label_type)
    end 
end 

function make_label(object::InstanceObjectType, instance::ProblemInstance, results::SolverResultsType, label_type::SolutionStability)
    hash = entropy_hash(results)
    entropy_median = median(values(hash))
    stable = hash[object.id] > entropy_median ? 0 : 1 
    return stable
end 