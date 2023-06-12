struct SplitDataset <: DatasetType
    split_time::Dates.DateTime # point in time that splits between training and testing instances. 
    training_dataset::SequentialDataset
    testing_dataset::SequentialDataset
end 
hparams_dict(d::SplitDataset) = error("TBD")


function SplitDataset(time::Dates.DateTime, training_radius::Int, testing_radius::Int; 
        number_training_instance::Int=10, 
        number_testing::Int=3)
    SplitDataset(
        time, 
        SequentialDataset(time, Backward(), number_training_instance, training_radius),
        SequentialDataset(time, Forward(), number_testing, testing_radius),
    )
end 


training_dataset(d::SplitDataset) = d.training_dataset
testing_dataset(d::SplitDataset) = d.testing_dataset

function get_training_results(d::SplitDataset)::Array{SolverResultsType, 1}
    get_results(d.training_dataset)
end 

function get_testing_results(d::SplitDataset)::Array{SolverResultsType, 1}
    get_results(d.testing_dataset)
end 

function get_spacetime_horizons(d::SplitDataset)::Array{SpaceTimeHorizon, 1}
    SpaceTimeHorizon[get_spacetime_horizons(d.training_dataset)..., get_spacetime_horizons(d.testing_dataset)...]
end 
