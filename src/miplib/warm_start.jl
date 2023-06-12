function warm_start_miplib()
    @info "Warming up by solving easy miplib instance..."
    dataset = EasyMiblibDataset()
    task_id = 1
    key = get_key_from_task_id(dataset, task_id)
    scenario = key.scenario
    instance = build_instance!(scenario)
    build_and_solve_mip!(instance, algorithm=key.algorithm, save_results=false)
    @show metrics_dict(instance)
    @info "Warm up done"
end 
export warm_start_miplib
