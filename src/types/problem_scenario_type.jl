abstract type ProblemScenario end 

# Lap 
struct LapScenario <: ProblemScenario 
    st::SpaceTimeHorizon 
end 
to_string(s::LapScenario)::String =  to_string(s.st)

# We have an issue here where the dict is non ordered. 
# Therefore, the parsing is non-deterministic which causes issue for retriving historical data. 


# Lpp 
abstract type WeightDistribution end 
abstract type LengthDistribution end 
abstract type ContainerDistributionType end 
abstract type RailcarFactory end 
abstract type ContainerFactory end 
abstract type RailcarDistributionType end 

struct LppScenario <: ProblemScenario 
    seed::Int 
    container_distribution::ContainerDistributionType
    railcar_distribution::RailcarDistributionType
    with_container_weight_noise::Bool
    container_assignments_relaxed::Bool
    enable_usage_discount::Bool
    formulation::Formulation
end 

function to_string(s::ProblemScenario)::String 
    json_str = JSON.json(s)
    return json_str
end 

typedict(s::ProblemScenario) = typedict_json(s)

struct CanadScenario <: ProblemScenario 
    name::String 
    number_of_nodes::Int
    number_of_arcs::Int
    number_of_commodities::Int
    arc_data::DataFrame 
    commodity_data::DataFrame
end 

get_formulation(::CanadScenario) = MultiCommodity()
to_string(s::CanadScenario) = s.name
function Base.show(io::IO, i::CanadScenario) 
    println(io, "Canad scenario $(i.name), #nodes: $(i.number_of_nodes) #arcs: $(i.number_of_arcs), #commodities: $(i.number_of_commodities).") 
end 

function typedict(s::CanadScenario)
    Dict(
        "canad_id" => s.name
    )
end 

include("perturbation_type.jl")
