struct TerminationMetrics 
    time_to_solve::Number 
    objective_value::Union{Number, Missing}  
    is_optimal::Bool 
    gap::Union{Number, Missing}  
end     

function TerminationMetrics(model::JumpModel)
    TerminationMetrics(
        get_time_to_solve(model),
        get_objective_value(model),
        is_optimal(model),
        get_optimality_gap(model)
    )
end     

function typedict(metrics::TerminationMetrics)
    Dict{String, Any}(
        "time_to_solve" => metrics.time_to_solve,
        "objective_value" => metrics.objective_value,
        "is_optimal" => metrics.is_optimal,
        "gap" => metrics.gap,
        "optimality_gap" => metrics.gap # more explicit name 
    )
end 

function Base.show(io::IO, m::TerminationMetrics)
    s = "Time to solve ⏰: $(m.time_to_solve), Gap: $(m.gap), Optimal: $(m.is_optimal)" 
    println(io, s)
end 