abstract type StateType end 
abstract type SolverResultsType end 

mutable struct CallbackState <: StateType
    instance::ProblemInstance
    tree::BnBTree 
    stats::Union{Missing, StatisticsType}
    lazy_constraints::Array{LazyConstraintType, 1}
    model::JumpModel
    cb_data::Union{Missing, CPLEX.CallbackContext}
    context_id::Union{Missing, Clong}
    info::Dict{String, Any}
    CallbackState(instance, model) = new(instance, BnBTree(), missing, LazyConstraintType[], model, missing, missing, Dict{String, Any}("benchmarks" => []))
end 

mutable struct PresolveState <: StateType 
    instance::ProblemInstance
    model::JumpModel
    info::Dict{String, Any}
end 
PresolveState(i::ProblemInstance, m::JumpModel) = PresolveState(i, m, Dict())

# Used to simulate a previous run for training purposes.
mutable struct TrainingCallbackState <: StateType 
    instance::ProblemInstance
    tree::BnBTree 
    stats::Union{Missing, StatisticsType}
    lazy_constraints::Array{LazyConstraintType, 1}
    results::SolverResultsType
    info::Dict{String, Any}
end 
