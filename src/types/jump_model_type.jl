# Wrapper around the jump model object 
mutable struct JumpModel
    model 
end 

function get_binary_variables(model::JumpModel)::Array{JuMP.VariableRef, 1}
    variables = JuMP.all_variables(model.model) 
    filter(variables) do variable 
        JuMP.is_binary(variable)
    end 
end

function get_all_variables(model::JumpModel)::Array{JuMP.VariableRef, 1}
    JuMP.all_variables(model.model)
end

function get_equal_to_constraints(model::JumpModel)::Array{JuMP.ConstraintRef, 1}
    JuMP.all_constraints(model.model, AffExpr, MOI.EqualTo{Float64})
end

function get_vars(constraint::JuMP.ConstraintRef)::Array{JuMP.VariableRef, 1}
    constraint_object = JuMP.constraint_object(constraint)
    terms_dict = constraint_object.func.terms
    var_list = []
    
    for (var, coef) in terms_dict
        push!(var_list, var)
    end
    var_list
end

function get_variable_references(constraint::JuMP.ConstraintRef)::Array{JuMP.VariableRef, 1}
    get_vars(constraint)
end

function get_sos_solution_df(m::JumpModel)::DataFrame 
    constraints = get_equal_to_constraints(m)
    data = []
    for constraint in constraints
        metrics = constraint_metrics(constraint)
        if metrics[:is_sos]
            vars = get_vars(constraint)
            for var in vars 
                value = JuMP.value(var)
                if value == 1.0
                    dict =  Dict(
                        :variable_index=>JuMP.index(var).value |> Int, 
                        :constraint_index=>JuMP.index(constraint).value |> Int,
                        :sos_set_size=>metrics[:sos_set_size]|> Int,
                    )
                    push!(data, dict)
                end
            end 
        end
    end
    to_df_from_dict(data)
end 
is_jump_model_optimal(model)::Bool = termination_status(model) == MOI.OPTIMAL
is_jump_model_timed_out(model)::Bool = termination_status(model) == MOI.TIME_LIMIT 

function get_jump_var(model, var::Symbol)
    JuMP.value(model[var]) 
end 

function get_value(model::JumpModel, var::Symbol, i::Int, j::Int)
    JuMP.value(get_var(model, var)[i, j])
end     

function get_var(m::JumpModel, var::Symbol)
    m.model[var]
end 

function get_objective_value(m::JumpModel)
    if JuMP.has_values(m.model)
        JuMP.objective_value(m.model)
    else
        NaN
    end
end 
is_optimal(m::JumpModel) = is_jump_model_optimal(m.model)
# https://jump.dev/MathOptInterface.jl/v0.9.14/apireference/#MathOptInterface.RelativeGap
function get_optimality_gap(m::JumpModel) 
    if JuMP.has_values(m.model)
        MOI.get(m.model, MOI.RelativeGap())
    else
        NaN
    end
end 
# get_time_to_solve(m::JumpModel) = MOI.get(m.model, MOI.SolveTime())
get_time_to_solve(m::JumpModel) = MOI.get(m.model, MOI.SolveTimeSec())

set_callback!(m::JumpModel, callback::Function) = MOI.set(m.model, CPLEX.CallbackFunction(), callback)
set_optimizer(m::JumpModel, opt) = JuMP.set_optimizer(m.model, opt)
optimize!(m::JumpModel) = JuMP.optimize!(m.model)