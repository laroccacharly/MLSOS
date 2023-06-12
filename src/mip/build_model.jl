
function init_jump_model!(a::MIPAlgorithm=CPLEXAlgorithm()) 
    opt = build_optimizer!(a)
    model = JuMP.Model(opt) 
    return model 
end 

function build_optimizer!(a::MIPAlgorithm=CPLEXAlgorithm()) 
    @info "Init CPLEX solver with params: "
    display(typedict(solver_params(a)))
    return optimizer_with_attributes(CPLEX.Optimizer, typedict(solver_params(a))...) 
end

function set_number_of_threads!(model::JuMP.Model, n::Int=1) 
    MOI.set(model, MOI.NumberOfThreads(), n)
end

function build_and_solve_mip!(instance::ProblemInstance; algorithm::MIPAlgorithm=CPLEXAlgorithm(), enable_callback::Bool=true, save_results::Bool=true, return_state::Bool=false)
    if jump_model_is_built(instance)
        @info "The JuMP model has already been built. Skipping build."
        model = get_jump_model(instance)
    else 
        model = init_jump_model!(algorithm)
        model = build_mip!(instance, model)
    end
    nthreads = get_nthreads(solver_params(algorithm))
    set_number_of_threads!(model, nthreads)
    if nthreads > 1 
        @info "Using more than 1 thread. Disabling callback."
        enable_callback = false
    end

    presolve_state = PresolveState(instance, JumpModel(model))
    add_additional_constraints!(presolve_state, algorithm)
    model = presolve_state.model
    opt = build_optimizer!(algorithm)
    set_optimizer(model, opt)
    # Callback 
    # The idea here is to call external functions in the registered callback to move the callback code in another file. 
    state = CallbackState(instance, model)
    function registered_callback(cb_data::CPLEX.CallbackContext, context_id::Clong)
        state.cb_data = cb_data
        state.context_id = context_id
        if state.context_id == CPLEX.CPX_CALLBACKCONTEXT_LOCAL_PROGRESS
            return 
        end 
        time_to_collect_data = @elapsed collect_data_callback(state, algorithm)
        time_to_run_algorithm = @elapsed algorithm_callback(state, algorithm)
        add_benchmarks!(state, Dict{String, Any}(
            "time_to_collect_data" => time_to_collect_data,
            "time_to_run_algorithm" => time_to_run_algorithm,
        ))
    end 
    if enable_callback 
        set_callback!(model, registered_callback)
    end 

    # Solving 
    @info "Solving $instance (id: $(get_id(instance))) with algorithm $(name(algorithm))"
    optimize!(model)
    
    if !is_optimal(model)
        @warn "Not solved to optimality"
    end 

    # Saving results 
    if has_values(model.model)
        best_solution = get_sos_solution_df(model)
    else 
        @warn "Cannot save solution because no solution was found"
        best_solution = missing
    end 
    metrics = TerminationMetrics(model)
    
    dicts = [
        typedict(metrics),
        typedict(algorithm),
        Dict("algorithm" => name(algorithm)),
        Dict("instance_id" => get_id(instance)),
        Dict("created_at" => Dates.now()),
        Dict("problem_name" => problem_name(instance)),
        Dict("cplex_time_limit" => cplex_time_limit()),
    ]
    dicts = merge(dicts...)

    dataframes = [
        get_dataframes(algorithm),
        Dict("benchmarks" => get_benchmarks(state)),   
        Dict("lazy_constraints" => get_lazy_constraints_df(state)), 
        get_dataframes(state.tree),
        ismissing(best_solution) ? Dict() : Dict("best_solution" => best_solution), 
    ]
    dataframes = merge(dataframes...)
    rdf = SolverResultsDF(rand_id(), dataframes, dicts)
    if save_results
        save(rdf)
    end

    if return_state
        return rdf, state
    end
    return rdf
end