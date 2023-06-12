abstract type ScoresType end
abstract type ScoringType end

struct RandomScore <: ScoringType 
end 
name(s::RandomScore) = "random"

struct HistoricalEntropyScore <: ScoringType 
end 
name(s::HistoricalEntropyScore) = "historical_entropy"
