struct WrappedDataset <: DatasetType 
    dataset::DatasetType
    funct::Function 
end 

function get_scenarios(d::WrappedDataset)
    d.funct.(get_scenarios(d.dataset))
end