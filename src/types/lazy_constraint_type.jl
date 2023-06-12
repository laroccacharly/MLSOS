abstract type LazyConstraintType end

struct SingleSolutionConstraint <: LazyConstraintType
    node_uuid::String
    object_id::Int 
    label::Number 
    label_type::LabelType
end 
get_object_id(c::SingleSolutionConstraint) = c.object_id
name(c::SingleSolutionConstraint) = "single"
function typedict(c::SingleSolutionConstraint)
    typedict_json(c)
end 

abstract type RangeConstraintType end
struct RangeConstraint <: LazyConstraintType
    arc_id::Int 
    consist_gap_min::Int
    consist_gap_max::Int
end 
name(c::RangeConstraint) = "range"

#=
struct FreezingConstraint <: LazyConstraintType
    var::JuMP.VariableRef
    value::Number 
end 
name(c::FreezingConstraint) = "freezing"
function typedict(c::FreezingConstraint)
    Dict(
        "index" => JuMP.index(c.var).value,
        "value" => c.value
    )
end =# 