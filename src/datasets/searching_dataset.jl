struct SearchingDataset <: DatasetType
end 

function condition(::SearchingDataset, r::SolverResultsType)::Bool
    is_lpp::Bool = get(r.info, "problem_name", "lap") == "lpp"
    is_user_cut::Bool = get(r.info, "callback_action_type", "missing") == "user_cut"
    created_at = get(r.info, "created_at", "19/04/2022 16:07:55") |> to_datetime
    correct_time::Bool = created_at < to_datetime("8/04/2022 16:07:00") && created_at > to_datetime("6/04/2022 16:07:00")
    is_lpp && correct_time
end 

function get_results(d::SearchingDataset)
    db = get_db() 
    results = db.results 
    filter(
        r -> condition(d, r), 
        results
    )
end 

