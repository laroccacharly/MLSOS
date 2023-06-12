function run_slurm(dataset)
    task_id = get(ENV, "TASK_ID", missing)
    should_compute_metrics = get(ENV, "COMPUTE_METRICS", "0") == "1"

    if ismissing(task_id) || task_id == ""
        @warn "TASK_ID is missing. Running no task"
        missing_ids = show_missing_task_ids(dataset)
        save_json(Dict("missing_ids" => missing_ids), "missing_ids", "")
    else
        task_id = parse(Int, task_id)
        if is_task_id_valid(dataset, task_id)
            @info "TASK_ID is valid"
            build(dataset, task_id)
            if should_compute_metrics
                compute_metrics(dataset, task_id)
            end
        else
            @warn "TASK_ID is invalid. Running no task"
        end
    end
end 
export run_slurm