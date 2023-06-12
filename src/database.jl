include("primary_key.jl")

struct ResultsDataBase <: DataBaseType
    results::Array{SolverResultsType, 1}
    results_hash::Dict{String, Int} # key -> array position 
end 

function get_result(db::DataBaseType, key::PrimaryKey)::SolverResultsType
    s = db.results[db.results_hash[to_string(key)]]
    set_key!(s, key)
end 

function is_available(db::DataBaseType, key::PrimaryKey)::Bool
    value = get(db.results_hash, to_string(key), missing)
    !ismissing(value)
end 

function is_available(db::DataBaseType, st::SpaceTimeHorizon)::Bool 
    is_available(db, PrimaryKey(st))
end 

function make_cplex_key(s::SolverResultsType)::PrimaryKey
    key = get_key(s)
    PrimaryKey(key.scenario, CPLEXAlgorithm()) 
end 

function make_cplex_key(s::SolverResults)::PrimaryKey
    PrimaryKey(get_scenario(get_instance(s)), CPLEXAlgorithm()) 
end 

function get_cplex_results(s::SolverResultsType)
    cplex_key = make_cplex_key(s)
    r = get_result(get_db(), cplex_key)
    return r 
end 

function is_cplex_results_available(s::SolverResultsType)
    cplex_key = make_cplex_key(s)
    is_available(get_db(), cplex_key)
end

function ResultsDataBase()
    results = load_all_results() 
    results_hash = Dict{String, Int}()
    for (index, result) in enumerate(results) 
        key = PrimaryKey(result)
        if !ismissing(get(results_hash, to_string(key), missing))
            @warn "Duplicate results for $key"
            delete!(result)
        end 
        results_hash[to_string(key)] = index
    end 
    ResultsDataBase(results, results_hash)
end 

function clear_db_cache!() 
    @info "Clearing db cache"
    global results_db = missing 
end 

results_db = missing 
function get_results_db()::DataBaseType
    if !ismissing(results_db)
        return results_db
    end 
    global results_db = ResultsDataBase()
end 