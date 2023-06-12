struct SOSConstraint <: SOSConstraintType
    id::Int
    constraint_reference::JuMP.ConstraintRef
    variable_references::Vector{JuMP.VariableRef}
    weights::Vector{Float64}
    info::Dict{Any, Any}
end  

function SOSConstraint(id::Int, constraint_reference::JuMP.ConstraintRef, variable_references::Vector{JuMP.VariableRef}; weights::Vector{Float64}=Float64[], info=Dict)
    sos_set_size = length(variable_references)
    SOSConstraint(id, constraint_reference, variable_references, weights, merge(info, Dict{Any, Any}(:sos_set_size => sos_set_size)))
end
get_sos_set_size(sos_constraint::SOSConstraintType) = sos_constraint.info[:sos_set_size]
get_variable_references(sos_constraint::SOSConstraintType)::Vector{JuMP.VariableRef} = sos_constraint.variable_references
function get_sos_constraint_references(model::JuMP.Model)::Vector{JuMP.ConstraintRef}
    constraints = JuMP.all_constraints(model, AffExpr, MOI.EqualTo{Float64})
    sos_constraints = []
    for constraint in constraints
        metrics = constraint_metrics(constraint)
        if metrics[:is_sos]
            push!(sos_constraints, constraint)
        end
    end
    sos_constraints
end

function build_sos_constraints(model::JuMP.Model)::Vector{SOSConstraintType}
    constraint_references = get_sos_constraint_references(model)
    sos_constraints = []
    for (index, constraint_reference) in enumerate(constraint_references)
        variable_references = get_variable_references(constraint_reference)
        sos_constraint = SOSConstraint(index, constraint_reference, variable_references)
        push!(sos_constraints, sos_constraint)
    end
    sos_constraints
end


# function SOSConstraint()