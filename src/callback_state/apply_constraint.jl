function apply!(state::CallbackState, action::ActionType)
    for constraint in build_jump_constraints(state, action)
        submit_MOI_constraint!(state, constraint, get_value("callback_action_type"))
    end 
    push!(state, action.constraint)
end 

function apply!(state::StateType, constraint::LazyConstraintType)
    push!(state, constraint)
end 

function apply!(state::CallbackState, constraint::LazyConstraintType)
    submit_MOI_constraint!(state, constraint)
    push!(state, constraint)
end 

function Base.push!(state::StateType, constraint::LazyConstraintType)
    push!(state.lazy_constraints, constraint)
end 

function convert_label_into_index(state::CallbackState, object::InstanceObjectType, label::Number, label_type::LabelType)
    return label 
end 

function convert_label_into_index(state::StateType, arc::Arc, consist_gap::Number, label_type::ConsistGap)
    consist_id = convert_consist_gap_to_id(consist_gap, arc.id, state.instance)
    return consist_id 
end 

function convert_label_into_index(state::CallbackState, arc::Arc, consist_gap::Number, label_type::ConsistGap)
    consist_id = convert_consist_gap_to_id(consist_gap, arc.id, state.instance)
    return consist_id 
end 

function show_constraint(state::CallbackState, constraint::SingleSolutionConstraint, ::LabelType)

end 

function show_constraint(state::CallbackState, constraint::SingleSolutionConstraint, ::RailcarLoadingPatternAssignment)
    object_id = get_object_id(constraint)
    railcar = get_object(state.instance, object_id)
    # @show railcar 
    @show railcar.id 
    @show label = constraint.label 
    #loading_patterns = get_loading_patterns(state.instance)
    #Base.show(loading_patterns[label])
end 

function show_constraint(state::CallbackState, constraint::SingleSolutionConstraint, ::ConsistGap)
    object_id = get_object_id(constraint)
    arc = get_object(state.instance, object_id)
    @info "Apply constraint to LAP"
    @show arc 
    @show label = constraint.label 
end 

is_constraint_valid(::StateType, ::SingleSolutionConstraint, ::LabelType) = true 
function is_constraint_valid(state::CallbackState, constraint::SingleSolutionConstraint, ::RailcarLoadingPatternAssignment)
    is_valid::Bool = constraint.label != 0 
    if !is_valid
        @show constraint
        @warn "We do not support fixing a railcar loading pattern to 0. "
    end 
    return is_valid
end 

build_jump_constraints(state::StateType, action::AddLazyConstraint) = build_jump_constraints(state::StateType, action::AddLazyConstraint, action.constraint.label_type) 
# Redo this to check if current value == target_value 
function build_jump_constraints(state::StateType, action::AddLazyConstraint, label_type::LabelType)
    if !is_constraint_valid(state, action.constraint, label_type)
        return []
    end 
    object = get_object(state.instance, action.constraint.object_id)
    index = convert_label_into_index(state, object, action.constraint.label, action.constraint.label_type)
    con = @build_constraint(state.model.model[mip_var_sym(object)][object.id, index] == 1) 
    return [con]
end 

function build_jump_constraints(state::StateType, action::AddLazyConstraint, ::VarRefLabelType)
    object = get_object(state.instance, action.constraint.object_id)
    variable_references = get_variable_references(object)
    var_ref = missing 
    var_ref_index = action.constraint.label

    for variable_reference in variable_references
        local_var_ref_index = Int(JuMP.index(variable_reference).value)
        if local_var_ref_index == var_ref_index
            var_ref = variable_reference
            break
        end 
    end
    @assert !ismissing(var_ref) "Could not find variable reference with index $var_ref_index"
    con = @build_constraint(var_ref == 1) 
    return [con]
end 

function build_jump_constraints(state::StateType, action::AddLazyConstraint, label_type::FixedChargeLabel)
    object = get_object(state.instance, action.constraint.object_id)
    current_value = get_value(state, mip_var_sym(label_type), object.id)
    target_value = action.constraint.label
    if current_value ≈ target_value atol = 1e-2
        return []
    end 

    con = @build_constraint(state.model.model[mip_var_sym(label_type)][object.id] == target_value) 
    return [con]
end 

function submit_MOI_constraint!(state::CallbackState, constraint, ::LazyConstraint)
    @info "Applying LazyConstraint"
    MOI.submit(state.model.model, MOI.LazyConstraint(state.cb_data), constraint)
end 

function submit_MOI_constraint!(state::CallbackState, constraint, ::UserCut)
    if ismissing(constraint)
        return 
    end 
    @info "Applying UserCut $constraint"
    MOI.submit(state.model.model, MOI.UserCut(state.cb_data), constraint)
end 

# Deprecated 
function submit_MOI_constraint!(state::CallbackState, constraint::SingleSolutionConstraint)
    if !is_constraint_valid(state, constraint, constraint.label_type)
        return 
    end 
    object_id = get_object_id(constraint)
    object = get_object(state.instance, object_id)
    index = convert_label_into_index(state, object, constraint.label, constraint.label_type)
    if get_value(state, mip_var_sym(object), object.id, index) < 1
        if get_value("alternative_constraint_format")
            con = @build_constraint(state.model.model[mip_var_sym(object)][object.id, index] >= 0.99)
        else
            con = @build_constraint(state.model.model[mip_var_sym(object)][object.id, index] == 1) 
        end 
        show_constraint(state, constraint, constraint.label_type)
        @show con 
        submit_MOI_constraint!(state, con, get_value("callback_action_type"))
    else 
        @info "Already correct solution"
    end 
end 
