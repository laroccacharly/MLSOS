abstract type DataBaseType end

struct PrimaryKey
    scenario::Union{Missing, ProblemScenario}
    algorithm::Union{Missing, MIPAlgorithm}
    hash::String 
end 