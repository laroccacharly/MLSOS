# Trigger when we reach a specific number of nodes with solution in the BnB
mutable struct OneTimeScheduler <: SchedulerType
    triggered::Bool 
    number_of_nodes_with_solution::Int 
    OneTimeScheduler(n::Int) = new(false, n)
end 
JSON.lower(s::OneTimeScheduler) = "once_at_$(s.number_of_nodes_with_solution)"

function should_trigger(state::StateType, scheduler::OneTimeScheduler)::Bool 
    if scheduler.triggered
        return false 
    end 
    count = get_number_of_nodes_with_solution(state)
    context_id = get_context_id(state)
    if context_id in applicable_contexts(get_value("callback_action_type")) && count >= scheduler.number_of_nodes_with_solution
        @info "Triggered scheduler at $(count) nodes with solution"
        scheduler.triggered = true 
        return true 
    else 
        return false 
    end 
end 

function init_scheduler!(s::OneTimeScheduler) 
    s.triggered = false 
    return s 
end 

mutable struct TimeBudgetScheduler <: SchedulerType
    triggered::Bool 
    init_time::Dates.DateTime
    time_budget::Int # seconds 
    TimeBudgetScheduler(n::Int) = new(false, n)
end 
JSON.lower(s::TimeBudgetScheduler) = "$(s.time)s"


function init_scheduler!(s::TimeBudgetScheduler) 
    s.triggered = false 
    s.init_time = Dates.now()
    return s 
end 

function should_trigger(state::StateType, scheduler::TimeBudgetScheduler)::Bool 
    if scheduler.triggered
        return false 
    end 
    # Time elasped since the start of the algorithm
    time_elapsed = Dates.value(Dates.now() - scheduler.init_time) / 1000

    if time_elapsed >= scheduler.time_budget
        @info "Triggered scheduler at $(time_elapsed) seconds"
        scheduler.triggered = true 
        return true 
    else 
        return false 
    end 
end 


mutable struct RootScheduler <: SchedulerType
    triggered::Bool 
    RootScheduler() = new(false)
end 
JSON.lower(::RootScheduler) = "root_scheduler"

function should_trigger(state::StateType, scheduler::RootScheduler)::Bool 
    if scheduler.triggered
        return false 
    end 
    if state.context_id in applicable_contexts(get_value("callback_action_type"))
        @info "Triggered root scheduler"
        scheduler.triggered = true 
        return true 
    else 
        return false 
    end 
end 

function init_scheduler!(s::RootScheduler) 
    s.triggered = false 
    return s 
end 
init_scheduler!(s::SchedulerType) = s 


struct EveryNodeScheduler <: SchedulerType
    name::String
    EveryNodeScheduler() = new("every_node")
end 

function should_trigger(state::CallbackState, scheduler::EveryNodeScheduler)::Bool 
    state.context_id in applicable_contexts(get_value("callback_action_type"))
end 

struct EveryCandidateScheduler <: SchedulerType
    period::Int 
    name::String
    EveryCandidateScheduler(p::Int) = new(p, "every_candidate")
end 

function should_trigger(state::CallbackState, scheduler::EveryCandidateScheduler)::Bool 
    state.context_id == CPLEX.CPX_CALLBACKCONTEXT_CANDIDATE  && state.tree.number_candidates % scheduler.period == 0
end 