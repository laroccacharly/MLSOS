# Used to explore different instances sizes
struct ExplorationDataset <: DatasetType
    time::Dates.DateTime 
    number_instances::Int 
    radiuses::Array{Int, 1}
    layers::Array{SequentialDataset, 1}
end 
hparams_dict(d::ExplorationDataset) = Dict("number_instances" => d.number_instances, "radiuses" => d.radiuses, "time" => d.time)

function ExplorationDataset(time::Dates.DateTime, number_instances::Int, radiuses::Array{Int, 1})
    layers = map(radiuses) do radius 
        SequentialDataset(
            time, 
            Forward(),
            number_instances,
            radius
        )
    end     
    ExplorationDataset(
        time, 
        number_instances, 
        radiuses, 
        layers
    )
end 

function get_spacetime_horizons(dataset::ExplorationDataset)::Array{SpaceTimeHorizon, 1}
    sts = map(dataset.layers) do layer 
        get_spacetime_horizons(layer)
    end 
    return reduce(vcat, sts)
end 