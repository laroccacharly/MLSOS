
function metrics_dict(instance::MiplibInstanceType)
    merge(
        Dict(
            "instance_name" => name(instance),
            "objective_sense" => JuMP.objective_sense(instance.model) == MOI.MIN_SENSE ? "min" : "max"
        ),
        try_sos_metrics(instance.model),
    )
end 

function var_metrics_df(constraint::JuMP.ConstraintRef)
    constraint_object = JuMP.constraint_object(constraint)
    terms_dict = constraint_object.func.terms
    var_metric_list = []
    
    for (var, coef) in terms_dict
        is_integer = JuMP.is_integer(var)
        is_binary = JuMP.is_binary(var)
        is_integer_or_binary = is_integer || is_binary
        has_lower_bound = JuMP.has_lower_bound(var)
        has_upper_bound = JuMP.has_upper_bound(var)
        is_coef_one = coef == 1.0
        d = Dict(
            :is_integer_or_binary => is_integer_or_binary,
            :has_lower_bound => has_lower_bound,
            :has_upper_bound => has_upper_bound,
            :is_coef_one => is_coef_one,
        )
        push!(var_metric_list, d)
    end
    to_df_from_dict(var_metric_list)
end 

function constraint_metrics(constraint::JuMP.ConstraintRef)
    constraint_object = JuMP.constraint_object(constraint)
    right_hand_side = constraint_object.set.value
    is_right_hand_side_one::Bool = right_hand_side == 1.0
    df = var_metrics_df(constraint)
    coef_one_ratio = df[!, :is_coef_one] |> mean
    int_bin_ratio = df[!, :is_integer_or_binary] |> mean
    is_sos::Bool = coef_one_ratio == 1.0 && int_bin_ratio == 1.0 && is_right_hand_side_one
    sos_set_size = NaN
    if is_sos
        sos_set_size::Float64 = size(df, 1) + 0.0
    end
    Dict(
        :is_right_hand_side_one => is_right_hand_side_one,
        :coef_one_ratio => coef_one_ratio,
        :int_bin_ratio => int_bin_ratio,
        :is_sos => is_sos,
        :sos_set_size => sos_set_size,
    )
end 

function try_sos_metrics(model::JuMP.Model)
    try 
        sos_metrics(model)
    catch ex 
        @warn ex 
        return Dict(
            :sos_constraint_count => NaN,
            :average_sos_set_size => NaN,
            :sos_constraint_ratio => NaN,
            :greater_constraint_count => NaN,
            :lesser_constraint_count => NaN,
            :equal_to_constraint_count => NaN,
            :is_right_hand_side_one_ratio => NaN,
            :coef_one_ratio => NaN,
            :int_bin_ratio => NaN,
        )
    end
end     

function sos_metrics(model::JuMP.Model)
    greater_constraint_count::Float64 = JuMP.num_constraints(model, AffExpr, MOI.GreaterThan{Float64})
    lesser_constraint_count::Float64 = JuMP.num_constraints(model, AffExpr, MOI.LessThan{Float64})
    equal_to_constraint_count::Float64 = JuMP.num_constraints(model, AffExpr, MOI.EqualTo{Float64})

    if equal_to_constraint_count == 0 
        @warn "No equal to constraints in MIP"
        return Dict(
            :sos_constraint_count => NaN,
            :average_sos_set_size => NaN,
            :sos_constraint_ratio => NaN,
            :greater_constraint_count => greater_constraint_count,
            :lesser_constraint_count => lesser_constraint_count,
            :equal_to_constraint_count => equal_to_constraint_count,
            :is_right_hand_side_one_ratio => NaN,
            :coef_one_ratio => NaN,
            :int_bin_ratio => NaN,
        )
    end 
    equal_to_constaints = JuMP.all_constraints(model, AffExpr, MOI.EqualTo{Float64})
    constraint_metric_list = map(equal_to_constaints) do constraint
        constraint_metrics(constraint)
    end
    df = to_df_from_dict(constraint_metric_list)
    int_bin_ratio = df[!, :int_bin_ratio] |> mean
    coef_one_ratio = df[!, :coef_one_ratio] |> mean
    is_right_hand_side_one_ratio = df[!, :is_right_hand_side_one] |> mean
    sos_constraint_count::Float64 = df[!, :is_sos] |> sum
    # Filter NaN
    average_sos_set_size = df[!, :sos_set_size] |> x -> filter(!isnan, x) |> mean
    sos_constraint_ratio = sos_constraint_count / equal_to_constraint_count

    return Dict(
        :sos_constraint_count => sos_constraint_count,
        :average_sos_set_size => average_sos_set_size,
        :sos_constraint_ratio => sos_constraint_ratio,
        :greater_constraint_count => greater_constraint_count,
        :lesser_constraint_count => lesser_constraint_count,
        :equal_to_constraint_count => equal_to_constraint_count,
        :is_right_hand_side_one_ratio => is_right_hand_side_one_ratio,
        :coef_one_ratio => coef_one_ratio,
        :int_bin_ratio => int_bin_ratio,
    )
end