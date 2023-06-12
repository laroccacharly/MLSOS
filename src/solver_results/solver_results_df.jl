function load_results_df(id::String; base_path::String=results_base_path())::SolverResultsDF
    path = base_path * id * "/"
    @info "Loading results from disk at $path"
    dataframes = load_dataframes(file_storage_protocol(), path)

    SolverResultsDF(
        id, 
        dataframes,
        JSON.parsefile(path * "info.json") 
    )
end 

function save(s::SolverResultsDF)
    path = trymkdir(base_path(s) * s.id * "/")
    @info "Saving results in $path"
    @show s.info 
    
    for k in keys(s.dataframes)
        df = s.dataframes[k]
        if size(df, 1) == 0
            @warn "Not saving $k because it is empty"
            continue
        end
        save_df(file_storage_protocol(), path, k, df)
    end 

    save_json(s.info, "info", path)
end

function save_metrics(s::SolverResultsType, metrics)
    path = trymkdir(base_path(s) * s.id * "/")
    @info "Saving metrics in $path"
    metrics |> display
    save_json(metrics, "metrics", path)
end

function try_load_metrics(s::SolverResultsType)::Union{Dict, Missing}
    path = base_path(s) * s.id * "/"
    @info "Loading metrics from disk at $path"
    try 
        JSON.parsefile(path * "metrics.json")
    catch e
        @warn e 
        @warn "Could not load metrics from $path"
        @show get_key(s)
        missing 
    end 
end

function update_info!(s::SolverResultsDF, info::Dict{String, Any})
    path = trymkdir(base_path(s) * s.id * "/")
    @info "Updating info in $path"
    s.info = merge(s.info, info)
    save_json(s.info, "info", path)
end