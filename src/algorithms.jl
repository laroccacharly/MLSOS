include_folder("algorithms")

get_info(a::MIPAlgorithm) = Dict()
get_dataframes(a::MIPAlgorithm) = Dict() 
init!(a::MIPAlgorithm, data) = nothing 
name(a::MIPAlgorithm) = get_key(a)
solver_params(a::MIPAlgorithm)::SolverParamsType = CPLEXParams() 
get_key(a::MIPAlgorithm) = typedict(a) |> JSON.json 

function format_json(json::Dict, ::MIPAlgorithm)
    return json 
end 

function typedict(a::MIPAlgorithm)
    json = format_json(typedict_json(a), a)
    dicts = [
        json,
        typedict(solver_params(a)),
        has_learner(a) ? typedict(get_learner(a)) : Dict(),
    ]
    merge(dicts...)
end 

scheduler(a::MIPAlgorithm)::SchedulerType = a.scheduler 
has_scheduler(a::MIPAlgorithm) = false 
has_learner(a::MIPAlgorithm) = false

function add_additional_constraints!(state::StateType, algo::MIPAlgorithm)
    return state 
end 

function algorithm_callback(state::StateType, algo::MIPAlgorithm) 
    if !is_init(state) 
        init!(state, algo)
        return 
    end 

    if has_stats(algo)
        update_stats!(state)
    end 

    if should_trigger(state, scheduler(algo))
        actions = make_actions!(state, algo)     
        @info "Applying $(length(actions)) actions, $(get_number_of_nodes_with_solution(state)) nodes with solution"
        map(actions) do action
            apply!(state, action)
        end 
    end 
end 