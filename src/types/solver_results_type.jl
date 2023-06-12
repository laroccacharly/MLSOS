include("termination_metrics_type.jl")

struct SolverResults <: SolverResultsType
    instance::ProblemInstance
    algorithm::MIPAlgorithm 
    metrics::TerminationMetrics 
    tree::BnBTree
    lazy_constraints::Array{LazyConstraintType, 1}
    benchmarks::DataFrame
    info::Dict{String, Any}
    SolverResults(i, a, m, t, l, b) = new(i, a, m, t, l, b, Dict{String, Any}())
end    

# SolverResultsDF is a simplied version of SolverResults that can 
# be easily saved/loaded from disk 
struct SolverResultsDF <: SolverResultsType
    id::String 
    dataframes::Dict{String, DataFrame}
    info::Dict{String, Any}
end 

include("cached_info_type.jl")

# A "light" version of SolverResultsDF that does not store the dataframes
struct SolverResultsLight <: SolverResultsType
    id::String 
    info::Dict{String, Any}
end 



