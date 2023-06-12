function collect_solution_df(state::CallbackState)
    collect_solution_df(state, state.instance)
end 

function compute_best_sol(state::CallbackState)::Float64
    cplex_best_sol = get_cplex_dbl(state.cb_data, CPLEX.CPXCALLBACKINFO_BEST_SOL)
    # If CPLEX returns inf for best sol, we compute it manually. 
    if is_inf(cplex_best_sol) && state.context_id == CPLEX.CPX_CALLBACKCONTEXT_CANDIDATE
        best_sol = compute_objective_value(state, state.instance)
    elseif cplex_best_sol == 0 
        return 0 
    else 
        best_sol = cplex_best_sol
    end 

    @assert best_sol != 0 

    current_best_sol = get(state.info, "current_best_sol", missing)
    if ismissing(current_best_sol)
        state.info["current_best_sol"] = best_sol
    else 
        if state.info["current_best_sol"] > best_sol
            state.info["current_best_sol"] = best_sol
        end 
    end 
    state.info["current_best_sol"] |> Float64
end 

function show_compute_best_sol(state::CallbackState)
    if state.context_id != CPLEX.CPX_CALLBACKCONTEXT_CANDIDATE
        return 
    end 
    @show cplex_best_sol = get_cplex_dbl(state.cb_data, CPLEX.CPXCALLBACKINFO_BEST_SOL)
end 

function should_collect_callback_solution(state::StateType, algorithm::MIPAlgorithm)::Bool
    if state.context_id == CPLEX.CPX_CALLBACKCONTEXT_CANDIDATE
        return true 
    end 
    if !(state.context_id == CPLEX.CPX_CALLBACKCONTEXT_RELAXATION)
        return false 
    end
    if has_scheduler(algorithm)
        s = scheduler(algorithm)
        if s isa OneTimeScheduler
            if s.triggered
                return false 
            else 
                return true
            end 
        else 
            @warn "Scheduler might be collecting too much data"
            return true
        end
    end 
    return false 
end 

# The main job of this function is to collect the available information from CPLEX
function collect_data_callback(state::CallbackState, algorithm::MIPAlgorithm)
    context_id = state.context_id
    cb_data = state.cb_data
    node_uuid = rand_id() 
    state.info["node_uuid"] = node_uuid
    is_candidate::Int = context_id == CPLEX.CPX_CALLBACKCONTEXT_CANDIDATE ? 1 : 0 

    # Collecting candidate solution 
    if should_collect_callback_solution(state, algorithm)
        CPLEX.load_callback_variable_primal(cb_data, context_id)
        solution_df = collect_solution_df(state)
    else 
        solution_df = missing 
    end 

    # Collecting CPLEX info
    # https://www.ibm.com/docs/en/icos/12.10.0?topic=manual-cpxcallbackinfo
    cplex_info = Dict{String, Any}(
        "node_uuid" => node_uuid, 
        "context" => context_id_to_name(context_id), 
        "cplex_node_count" => get_cplex_int(cb_data, CPLEX.CPXCALLBACKINFO_NODECOUNT),
        "simplex_iterations" => get_cplex_int(cb_data, CPLEX.CPXCALLBACKINFO_ITCOUNT),
        "best_bnd" =>  get_cplex_dbl(cb_data, CPLEX.CPXCALLBACKINFO_BEST_BND),
        "best_sol" =>  compute_best_sol(state), 
        "cplex_best_sol" => get_cplex_dbl(cb_data, CPLEX.CPXCALLBACKINFO_BEST_SOL),
        "found_sol" => get_cplex_int(cb_data, CPLEX.CPXCALLBACKINFO_FEASIBLE),
        "node_depth" => get_cplex_long(cb_data, CPLEX.CPXCALLBACKINFO_NODEDEPTH),
        "cplex_node_id" => get_cplex_long(cb_data, CPLEX.CPXCALLBACKINFO_NODEUID),
        "time" => get_cplex_dbl(cb_data, CPLEX.CPXCALLBACKINFO_TIME),
        "number_candidates" => state.tree.number_candidates + is_candidate,
        "node_collected" => length(state.tree.nodes)
    )


    node = BnBNode(node_uuid, context_id, cplex_info, solution_df)
    # @show node 
    add_node!(state.tree, node)
end 