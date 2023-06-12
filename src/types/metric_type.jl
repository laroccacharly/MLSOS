abstract type MetricType end 

struct ActionAccuracy <: MetricType
end    
name(::ActionAccuracy) = "action_accuracy"

struct OptimalityGap <: MetricType 
end 
name(::OptimalityGap) = "optimality_gap"

struct RelativeGap <: MetricType 
end 
name(::RelativeGap) = "relative_gap"

struct TimeToFirstCandidate <: MetricType 
end 
name(::TimeToFirstCandidate) = "time_to_first_candidate"

struct NumberCandidates <: MetricType 
end 
name(::NumberCandidates) = "number_candidates"

struct TimeToBetterSolution <: MetricType 
end 
name(::TimeToBetterSolution) = "time_to_better_solution"

struct PrimalIntegral <: MetricType 
end 
name(::PrimalIntegral) = "primal_integral"

struct CplexPrimalIntegral <: MetricType 
end 
name(::CplexPrimalIntegral) = "cplex_primal_integral"

struct PrimalIntegralRatio <: MetricType 
end 
name(::PrimalIntegralRatio) = "PIR"

struct StrictlyBetterRatio <: MetricType 
end 
name(::StrictlyBetterRatio) = "SBR"

struct PrimalGaps <: MetricType 
end 
name(::PrimalGaps) = "primal_gaps"

struct RuntimeSpeedup <: MetricType 
end 
name(::RuntimeSpeedup) = "runtime_speed_up"