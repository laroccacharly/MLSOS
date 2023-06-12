get_label_type(::SOSConstraintType)::LabelType = VarRefLabel() 
get_label_type(::MiplibInstanceType)::LabelType = VarRefLabel()
get_label_type(::MiplibDatasetType)::LabelType = VarRefLabel() 

get_index_sym(::VarRefLabelType) = :object_id
get_symbol(::VarRefLabelType) = :var_ref
JSON.lower(::VarRefLabelType) = "var_ref"
function set_label!(object::InstanceObjectType, label_type::LabelType, label)
    object.info[label_type] = label
end