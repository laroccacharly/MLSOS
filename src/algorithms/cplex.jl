# CPLEX is the default algorithm, used to measure baseline 
struct CPLEXAlgorithm <: MIPAlgorithm
    name::String
    time_limit::Int
end 
export CPLEXAlgorithm
CPLEXAlgorithm() = CPLEXAlgorithm("cplex", cplex_time_limit())
CPLEXAlgorithm(time_limit::Int) = CPLEXAlgorithm("cplex", time_limit)
function algorithm_callback(state::CallbackState, algorithm::CPLEXAlgorithm) 
    return # Default CPLEX behavior, no additional changes
end 
has_stats(::CPLEXAlgorithm) = false  
init!(state::CallbackState, algo::CPLEXAlgorithm) = state 
solver_params(a::CPLEXAlgorithm)::SolverParamsType = CPLEXParams(;time_limit=a.time_limit)

function format_json(json::Dict, ::CPLEXAlgorithm)
    Base.delete!(json, "time_limit")
    return json 
end 