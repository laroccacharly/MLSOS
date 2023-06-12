struct MiplibScenario <: MiplibScenarioType 
    name::String
end
mps_filename(scenario::MiplibScenario) = scenario.name * ".mps"
zip_filename(scenario::MiplibScenario) = mps_filename(scenario) * ".gz"
name(scenario::MiplibScenario) = scenario.name
to_string(scenario::MiplibScenario) = name(scenario)

struct MiplibDataset <: MiplibDatasetType 
    scenarios::Vector{MiplibScenarioType}
end

function get_scenarios(dataset::MiplibDatasetType)
    dataset.scenarios
end 

load_miplib_cplex_metrics() = CSV.read(processed_data_path() * "cplex_performance_metrics_miplib.csv", DataFrame)

function EasyMiblibDataset()
    df = load_miplib_cplex_metrics()
    df = df[df[!, :time_to_solve] .< 60, :]
    names = df[!, :instance_name]

    scenarios = map(names) do name 
        MiplibScenario(name)
    end 
    MiplibDataset(scenarios)
end

function MediumMiplibDataset()
    df = load_miplib_cplex_metrics()
    df = df[df[!, :time_to_solve] .> 60, :]
    df = df[df[!, :time_to_solve] .< 3000, :]
    names = df[!, :instance_name]
    scenarios = map(names) do name 
        MiplibScenario(name)
    end 
    MiplibDataset(scenarios)
end 

function HardMiplibDataset()
    df = load_miplib_cplex_metrics()
    df = df[df[!, :time_to_solve] .> 3000, :]
    names = df[!, :instance_name]
    scenarios = map(names) do name 
        MiplibScenario(name)
    end 
    MiplibDataset(scenarios)
end

export EasyMiblibDataset, MediumMiplibDataset, HardMiplibDataset

