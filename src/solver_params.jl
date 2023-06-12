struct CPLEXParams <: SolverParamsType
    params::Dict{String, Any}
end 

function CPLEXParams(; presolve::Bool=true, time_limit= cplex_time_limit())
    # CPXPARAM_MIP_Strategy_CallbackReducedLP 0-1
    # CPXPARAM_Preprocessing_Presolve 0-1
    # CPXPARAM_MIP_Strategy_PresolveNode -1 or 0 
    # CPXPARAM_Preprocessing_Reduce  0-1
    params = Dict(
        "CPXPARAM_TimeLimit" => time_limit, 
        "CPX_PARAM_SCRIND" => show_cplex_stdout(), 
        "CPX_PARAM_THREADS" => get_nthreads(), 
    )
    if !presolve 
        params = merge(
            params, 
            Dict(
                "CPXPARAM_MIP_Strategy_CallbackReducedLP" => 0, 
                "CPXPARAM_Preprocessing_Presolve" => 0, 
                "CPXPARAM_MIP_Strategy_PresolveNode" => -1, 
                "CPXPARAM_Preprocessing_Reduce" => 0, 
            )
        )
    end 
    CPLEXParams(params)
end 

get_nthreads(c::CPLEXParams) = c.params["CPX_PARAM_THREADS"]
typedict(c::CPLEXParams) = c.params
