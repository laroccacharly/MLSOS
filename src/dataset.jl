# To build the training and the testing datasets, we only need instances solved by CPLEX
get_db() = get_results_db() 
function get_db(dataset::DatasetType)::DataBaseType
    get_db() 
end 

algorithm(d::DatasetType) = CPLEXAlgorithm()
training_dataset(d::DatasetType) = d
testing_dataset(d::DatasetType) = d

function get_scenarios(dataset::DatasetType)
    [LapScenario(st) for st in get_spacetime_horizons(dataset)] 
end 

get_all_result_keys(d::DatasetType) = result_keys(d)
function result_keys(dataset::DatasetType)::Array{PrimaryKey, 1}
    map(get_scenarios(dataset)) do st 
        PrimaryKey(st, algorithm(dataset))
    end     
end 

function check_if_results_are_missing(db::DataBaseType, dataset::DatasetType)::Bool 
    for key in result_keys(dataset)
        if !is_available(db, key)
            @warn "$key is missing"
            return true 
        end 
    end 
    return false 
end 

function get_missing_scenarios(dataset::DatasetType)
    missing_scenarios = ProblemScenario[]
    db = get_db(dataset)

    for (s, key) in zip(get_scenarios(dataset), result_keys(dataset))
        if is_available(db, key)
            @info "✅ Found $s"
        else
            @warn "Did not find $s"
            push!(missing_scenarios, s)
        end 
    end 
    if length(missing_scenarios) == 0
        @info "All scenarios are already solved"
        return missing_scenarios
    end 
    @info "There are $(length(missing_scenarios)) scenarios missing. Building them..."
    return missing_scenarios
end 

function build(d::DatasetType)
    @info "Building dataset $d"
    for scenario in get_missing_scenarios(d)
        instance = build_instance!(scenario)
        build_and_solve_mip!(instance)
    end 
    clear_db_cache!() 
    return d 
end 

function build_and_compute_metrics(dataset)
    build(dataset)
    compute_metrics(dataset)
end 

function get_results(d::DatasetType)::Array{SolverResultsType, 1}
    db = get_db(d)

    if check_if_results_are_missing(db, d)
        @warn "Some results are missing in dataset"
        # @error "Results are missing to load the dataset. Please run build(dataset) to solve the missing instances and clear db cache."
    end 

    results = SolverResultsType[] 
    for key in result_keys(d)
        if !is_available(db, key)
            @warn "$key is missing"
            continue 
        end 
        push!(results, get_result(db, key))
    end 
    

    return results 
end 

function delete!(d::DatasetType)
    results = get_results(d)
    delete!.(results)
    clear_db_cache!() 
end 

function upload!(dataset::DatasetType)
    map(get_results(dataset)) do result 
        upload!(result)
    end 
end 

function upload_dataset!(dataset::DatasetType = default_dataset())
    upload!(dataset)
end 

include("datasets/random_dataset.jl")
include("datasets/sequential_dataset.jl")
include("datasets/split_dataset.jl")
include("datasets/exploration_dataset.jl")
include("datasets/algorithm_dataset.jl")
include("datasets/merged_dataset.jl")
include("datasets/wrapped_dataset.jl")
include("datasets/searching_dataset.jl")

# main api
function default_split_dataset() 
    SplitDataset(
        test_instance_start_time() +  Day(100), # Day(20)
        650,
        850;
        number_training_instance=1,

    )
end 

function small_split_dataset()
    SplitDataset(
        test_instance_start_time() +  Day(100),
        650,
        900;
        number_training_instance=1,
        number_testing=10
    )
end 

function default_exploration_dataset()
    ExplorationDataset(
        test_instance_start_time() +  Day(100), 
        10,
        [900, 1200, 1600, 2200] # 3000
    )
end 

function small_lap_dataset()
    ExplorationDataset(
        test_instance_start_time() +  Day(100), 
        2,
        [450]
    ) 
end 

function medium_dataset()
    ExplorationDataset(
        test_instance_start_time() +  Day(100), 
        1,
        [900]
    )
end 

function many_algos_dataset() 
    algos = MIPAlgorithm[
        LearnerAlgorithm(ScorePolicy(HistoricalEntropyScore(), 1)),
        LearnerAlgorithm(ScorePolicy(HistoricalEntropyScore(), 5)),
        LearnerAlgorithm(ThresholdPolicy(0.5))
    ]
    ManyAlgorithmsDataset(default_exploration_dataset(), algos)
end 

function LapLearnerDataset()
    AlgorithmDataset(small_split_dataset(), LearnerAlgorithm(ScorePolicy(HistoricalEntropyScore(), 3)))
end 

function default_dataset()
    # AlgorithmDataset(small_split_dataset(), LearnerAlgorithm(ScorePolicy(HistoricalEntropyScore(), 3)))
    # many_algos_dataset() 
    #AlgorithmDataset(small_split_dataset(), Optimal(1.0, 1))
    # default_exploration_dataset() 
    DefaultLppDataset() 
    # oracle_lpp_dataset()
    # oracle_lpp_dataset_fixing_ratios()
    # oracle_lap_dataset_fixing_ratios() 
    #oracle_lap_dataset()
    # SmallLapDataset() 
end 

function delete_default_dataset!()
    delete!(default_dataset())
end 


function show_dataset()
    dataset = default_dataset() 
    @show get_scenarios(dataset)
end 

function build_dataset()
    default_dataset() |> build 
end 
