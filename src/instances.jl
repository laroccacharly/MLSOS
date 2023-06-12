function object_ids(instance::ProblemInstance)
    id(get_objects(instance))
end 
get_id(instance::ProblemInstance) = get_scenario(instance) |> to_string 
get_object(instance::ProblemInstance, object_id::Int) = get_objects(instance)[object_id]
serialize_into_dataframes(instance::ProblemInstance) = Dict() 
