function load_results_light(id::String; base_path::String=results_base_path())::SolverResultsLight
    path = base_path * id * "/"
    SolverResultsLight(
        id, 
        JSON.parsefile(path * "info.json") 
    )
end 

function load_results_df(rlight::SolverResultsLight)::SolverResultsDF
    load_results_df(rlight.id)
end 
