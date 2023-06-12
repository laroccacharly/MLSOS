struct MergedDataset <: DatasetType 
    datasets::Array{DatasetType, 1}
end
export MergedDataset

function get_missing_result_keys(d::MergedDataset)
    keys = [get_missing_result_keys(d) for d in d.datasets] 
    return vcat(keys...)
end 

function get_all_result_keys(d::MergedDataset)
    keys = [get_all_result_keys(d) for d in d.datasets] 
    return vcat(keys...)
end

function get_scenarios(d::MergedDataset)
    scenarios = [get_scenarios(d) for d in d.datasets]
    return vcat(scenarios...)
end

function get_results(d::MergedDataset)::Array{SolverResultsType, 1}
    results = [get_results(d) for d in d.datasets]
    return reduce(vcat, results)
end 