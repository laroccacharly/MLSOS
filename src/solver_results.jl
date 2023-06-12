include_folder("solver_results") 


get_id(s::SolverResults) = get_id(s.instance) 
get_id(s::SolverResultsType) = get_instance(s) |> get_id 
function algorithm(s::SolverResultsType)
    s.info["algorithm"]
end 
instance_id(s::SolverResultsType) = s.info["instance_id"]
problem_name(s::SolverResultsType) = get_instance(s) |> problem_name
global cached_results = SolverResultsType[] 
function save_in_cache!(results::SolverResultsType)
    push!(cached_results, results)
end 

# Where we store all the results 
function base_path(s::SolverResultsType)
    results_base_path()
end 

function get_path(s::SolverResultsType)
    base_path(s) * s.id
end 

function delete!(s::SolverResultsType)
    path = get_path(s)
    @warn "Deleting result @ $path"
    rm(path, recursive=true, force=true)
end 

function upload!(s::SolverResultsType)
    path = get_path(s)
    upload_folder_to_s3(path, path)
end 

function get_spacetime_horizon(results::SolverResultsType)::SpaceTimeHorizon
    SpaceTimeHorizon(results.info)
end 

function merge_dataframes(results::SolverResultsDF)::DataFrame 
    dfs = results.dataframes
    nodes = filter(r -> r.context == "CPX_CALLBACKCONTEXT_CANDIDATE", dfs["nodes"]) 
    df = innerjoin(dfs["solutions"], nodes, on = :node_uuid)
    df = innerjoin(df, dfs["trains"], on = :train_uuid)
    return df 
end 


function best_objective_value(s::SolverResultsType)
    s.info["objective_value"]
end 

function load_all_results()::Array{SolverResultsType, 1}
    path = results_base_path() 
    @info "Loading all results from $path"
    folder_names = myreaddir(path)
    results = SolverResultsType[]
    for id in folder_names 
        try 
            push!(results, load_results_light(id)) 
        catch ex 
            @warn ex 
            @warn "Could not load folder $id" 
        end     
    end 
    @info "Loaded $(length(results)) results"
    results 
end 

algorithm(s::SolverResults) = name(s.algorithm)

get_instance(r::SolverResults) = r.instance 
get_tree(r::SolverResults) = r.tree 
get_benchmarks(r::SolverResults) = r.benchmarks

function show_entropy_distribution(r::SolverResultsType)
    display(entropy_hash(r)) 
    #=
    instance = get_instance(r)
    for target_sym in get_target_syms(instance)
        entropies = [hash[merge_syms(Symbol(object_id), target_sym)] for object_id in object_ids(instance)]
        med = median(entropies)
        histogram(Number[v for v in entropies], title = "Entropy distribution for $target_sym. Median = $(med)") |> display 
    end=#  
end 

