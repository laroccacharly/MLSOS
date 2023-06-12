struct OneShotLearner <: LearnerType 
    info::Dict{String, Any}
end 
OneShotLearner() = OneShotLearner(Dict("metrics" => []))
name(::OneShotLearner) = "naive"
JSON.lower(s::OneShotLearner) = "naive_learner"

function fit!(learner::LearnerType, dataset::DatasetType)
    return learner 
end 

function make_prediction(state::StateType, learner::LearnerType, object::InstanceObjectType)
    get_most_likely_label(state.stats, object)
end 

function make_actions!(state::StateType, learner::LearnerType)
    actions = ActionType[]
    objects = select_objects_to_constraint(state)
    for object in objects
        action = make_action!(state, learner, object)
        push!(actions, action)
    end 
    return actions 
end 

function make_action!(state::StateType, learner::LearnerType, object::InstanceObjectType)
    label = make_prediction(state, learner, object)
    constraint = SingleSolutionConstraint(
        state.info["node_uuid"], object.id, label, get_label_type(state.instance)
    )
    AddLazyConstraint(constraint)
end 