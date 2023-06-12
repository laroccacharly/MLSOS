
function collect_solution_df(state::CallbackState, instance::ProblemInstance)::DataFrame
    df = collection_solution_df(state, instance, get_label_type(instance))
    insertcols!(df, 1, :node_uuid => [state.info["node_uuid"] for _ in size(df, 1)])
    return df 
end 

function collection_solution_df(state::CallbackState, instance::ProblemInstance, label_type::VarRefLabelType)
    solutions = []
    objects = get_objects(instance, label_type)
    for object in objects 
        variable_references = get_variable_references(object)
        values = []
        for variable_reference in variable_references
            value = get_value(state, variable_reference)
            if value < -0.01 || value > 1.01
                @warn "The value of the variable is not between 0 and 1."
                @show value 
            end
            push!(values, value)
        end

        # Some sanity checks.
        # Check if the sum of values is above 1
        if sum(values) > 1.01
            @warn "The sum of value of the variable is greater than 1."
            @show values 
        end
        # Get the index of the variable with the highest value
        max_index = argmax(values)
        var_ref = variable_references[max_index]
        var_ref_index = JuMP.index(var_ref).value |> Int

        solution = Dict(
            get_index_sym(label_type) => object.id, 
            get_symbol(label_type) => var_ref_index, 
        )
        push!(solutions, solution)
    end 

    return to_df_from_dict(solutions)
end 


compute_objective_value(state::CallbackState, ::ProblemInstance) = Inf64