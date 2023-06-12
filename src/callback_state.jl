include_folder("callback_state")

function current_node(state::CallbackState)::BnBNode
    best_candidate_node(state.tree)
end 

function is_init(state::StateType)
    get(state.info, "is_init", false)
end 

function init_stats!(state::StateType)
    set_stats!(state, BnBStats(state.instance)) 
end 

function generic_init!(state::StateType, algo::MIPAlgorithm)
    @info "Init callback state for algorithm $(name(algo))"
    if has_stats(algo)
        init_stats!(state)
    end 
    if has_scheduler(algo)
        scheduler(algo) |> init_scheduler!
    end 
    state.info["is_init"] = true 
end 

function init!(state::StateType, algo::MIPAlgorithm) 
    generic_init!(state, algo)
end 

function update_stats!(state::StateType)
    node = get_current_node(state)
    update!(state, node)
end 
update!(state::StateType, node::BnBNode) = update!(state.stats, node, state.instance)


function get_current_node(state::CallbackState)
    get_latest_node(state.tree)
end 

function get_context_id(state::StateType)
    node = get_current_node(state)
    node.cb_context_id
end 

function get_number_of_nodes_with_solution(state::StateType)
    stats = get_stats(state)
    get_number_of_nodes_with_solution(stats)
end 

function is_first_iteration(state::CallbackState)
    current_index(state.tree) == 0 && is_new_index(state)
end 

function is_new_index(state::CallbackState)::Bool
    index = current_index(state.tree)
    nodes = get_nodes_at_index(state.tree, index)
    length(nodes) == 1 ? true : false 
end 

function check_if_solution_respects_constraints(state::CallbackState, consist_gap::Int, arc::Arc, net::LapNet)
    if length(state.lazy_constraints) == 0 
        return 
    end 
    for constraint in state.lazy_constraints
        if arc.id == constraint.arc_id 
            if !is_within(constraint, consist_gap)
                @warn "Constraint not respected. $constraint, $arc, $consist_gap"
            end 
        end 
    end 
end 

get_lazy_constraints(state::CallbackState) = state.lazy_constraints

function get_constrained_object_ids(state::StateType)::Array{Int, 1}
    get_object_id.(get_lazy_constraints(state))
end 

function get_lazy_constraints_df(state::CallbackState)::DataFrame
    if length(state.lazy_constraints) == 0 
        return DataFrame()
    end
    to_df_from_dict(typedict.(state.lazy_constraints))
end

function set_stats!(state::StateType, stats::BnBStats)
    state.stats = stats
end 

get_stats(state::StateType)::BnBStats = state.stats

function cheapest_consist_id(state::CallbackState, arc_id::Int)::Int
    return cheapest_consist_id(state.net, arc_id)
end 

function add_benchmarks!(state::CallbackState, benchmarks::Dict{String, Any})
    dict = merge(Dict(
        "node_uuid" => state.info["node_uuid"],
    ), benchmarks) 
    push!(state.info["benchmarks"], dict)
end 

function get_benchmarks(state::CallbackState)::DataFrame 
    if length(state.info["benchmarks"]) == 0 
        return DataFrame()
    end
    to_df_from_dict(state.info["benchmarks"])
end 

function get_value(state::CallbackState, var::Symbol, i::Int, j::Int)
    callback_value(state.cb_data, get_var(state.model, var)[i, j]) 
end 

function get_value(state::CallbackState, var::Symbol, i::Int)
    callback_value(state.cb_data, get_var(state.model, var)[i]) 
end 

function get_value(state::StateType, var::JuMP.VariableRef)
    callback_value(state.cb_data, var) 
end

# For some reason, you cannot add a constraint if the current solution is within it. 
# This function checks if the constraint is already satisfied. 
function is_already_satisfied(state::CallbackState, var::Symbol, i::Int, j::Int, value::Number)::Bool
    callback_value(state.cb_data, get_var(state.model, var)[i, j]) == value 
end 

function is_already_satisfied(state::StateType, var::Symbol, i::Int, j::Int, value::Number)::Bool 
    false
end 