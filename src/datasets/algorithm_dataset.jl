mutable struct AlgorithmDataset <: DatasetType 
    cplex_dataset::DatasetType 
    algorithm::MIPAlgorithm 
end 
algorithm(d::AlgorithmDataset)::MIPAlgorithm = d.algorithm

function get_scenarios(d::AlgorithmDataset)
    get_scenarios(testing_dataset(d.cplex_dataset))
end 

function build(d::AlgorithmDataset)
    db = get_db(d)
    cplex_dataset = d.cplex_dataset
    algo = d.algorithm
    build(cplex_dataset) # This should be instant if already built. 
    init!(algo, training_dataset(cplex_dataset))
    test_results = get_results(testing_dataset(d.cplex_dataset))
    for (key, result) in zip(result_keys(d), test_results) 
        if is_available(db, key)
            @info "✅ Found $key"
        else 
            @info "Did not find $key. Building it..."
            instance = get_instance(result)
            build_and_solve_mip!(instance, algorithm=algo) 
        end 
    end 
    clear_db_cache!() 
    return d 
end 

mutable struct ManyAlgorithmsDataset <: DatasetType 
    cplex_dataset::DatasetType 
    algorithms::Array{MIPAlgorithm, 1} 
end 
export ManyAlgorithmsDataset

function get_scenarios(d::ManyAlgorithmsDataset)
    get_scenarios(testing_dataset(d.cplex_dataset))
end

function get_missing_result_keys(d::ManyAlgorithmsDataset)
    missing_result_keys = PrimaryKey[]
    db = get_db(d)
    cplex_dataset = d.cplex_dataset
    algos = d.algorithms
    for algo in algos
        for key in result_keys(AlgorithmDataset(cplex_dataset, algo))
            if !is_available(db, key)
                push!(missing_result_keys, key)
            end 
        end 
    end 
    @info "Found $(length(missing_result_keys)) missing results"
    return missing_result_keys
end

function get_all_result_keys(d::ManyAlgorithmsDataset)
    keys = PrimaryKey[]
    cplex_dataset = d.cplex_dataset
    algos = d.algorithms
    for algo in algos
        for key in result_keys(AlgorithmDataset(cplex_dataset, algo))
            push!(keys, key)
        end 
    end 
    return keys
end

function show_missing_task_ids(dataset::DatasetType)
    task_id_to_key = Dict([(i, key) for (i, key) in enumerate(get_all_result_keys(dataset))])
    key_to_task_id = Dict([(key, i) for (i, key) in enumerate(get_all_result_keys(dataset))])

    all_keys = get_all_result_keys(dataset)
    missing_keys = get_missing_result_keys(dataset)
    missing_ids = [key_to_task_id[key] for key in missing_keys]
    @info "Dataset has $(length(all_keys)) tasks"
    @info "Missing $(length(missing_keys)) tasks" 
    for key in missing_keys
        @info "Missing task_id: $(key_to_task_id[key])"
        @info "Missing key: $key"
    end
    return missing_ids
end

function key_string_to_task_id(dataset::DatasetType, key_string::String)::Int
    all_keys = get_all_result_keys(dataset)
    key_to_task_id = Dict([(key.hash, i) for (i, key) in enumerate(all_keys)])
    return key_to_task_id[key_string]
end
export key_string_to_task_id

function is_task_id_valid(dataset::DatasetType, task_id::Int)::Bool
    all_keys = get_all_result_keys(dataset)
    return task_id <= length(all_keys)
end
export is_task_id_valid

function get_key_from_task_id(dataset::DatasetType, task_id::Int)::PrimaryKey
    all_keys = get_all_result_keys(dataset)
    if !is_task_id_valid(dataset, task_id)
        error("Task id is not valid")
    end
    return all_keys[task_id]
end

function build(d::DatasetType, task_id::Int)
    key = get_key_from_task_id(d, task_id)
    db = get_db(d)
    if !is_available(db, key)
        @info "Did not find $key. Building it..."
        @info "TASK_ID: $task_id"
        scenario = key.scenario
        instance = build_instance!(scenario)
        results = build_and_solve_mip!(instance, algorithm=key.algorithm)
        results.info |> display
    else 
        @info "✅ Found $key"
    end    
    clear_db_cache!()
end

function build(d::ManyAlgorithmsDataset)
    missing_result_keys = get_missing_result_keys(d)
    for (index, key) in enumerate(missing_result_keys)
        @info "Progression: $index of $(length(missing_result_keys))"
        @info "Building:  $key"
        scenario = key.scenario
        instance = build_instance!(scenario)
        build_and_solve_mip!(instance, algorithm=key.algorithm)
    end
    clear_db_cache!() 
end 

function get_results(d::ManyAlgorithmsDataset)::Array{SolverResultsType, 1}
    results = map(d.algorithms) do algo 
        get_results(AlgorithmDataset(d.cplex_dataset, algo))
    end 
    return reduce(vcat, results)
end 

has_cplex_dataset(::DatasetType) = false 
has_cplex_dataset(::AlgorithmDataset) = true  
has_cplex_dataset(::ManyAlgorithmsDataset) = false  




