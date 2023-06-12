struct RandomDataset <: DatasetType
    number_instances::Int 
end 

hparams(d::RandomDataset) = "n=$(d.number_instances)"
hparams_dict(d::RandomDataset) = Dict("number_instances" => d.number_instances)

function get_results(d::RandomDataset)  
    db = get_db(d)
    return sample(db.results, d.number_instances)
end 
