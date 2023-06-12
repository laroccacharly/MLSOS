function PrimaryKey(hash::String)
    PrimaryKey(missing, missing, hash)
end 

function PrimaryKey(st::ProblemScenario, algorithm::MIPAlgorithm=CPLEXAlgorithm())
    PrimaryKey(st, algorithm, to_string(st) * name(algorithm))
end 

function PrimaryKey(s::SolverResultsType)
    PrimaryKey(instance_id(s) * algorithm(s)) 
end 

function set_key!(s::SolverResultsType, key::PrimaryKey)
    s.info["primary_key"] = key 
    return s 
end 

get_key(s::SolverResultsType)::Union{Missing, PrimaryKey} = get(s.info, "primary_key", missing) 

to_string(key::PrimaryKey)::String = key.hash 