# Policies take actions (adding lazy constraints) based on the available information. 
struct ThresholdPolicy <: PolicyType
    threshold::Number 
end 
threshold(p::ThresholdPolicy) = p.threshold
hparams(p::ThresholdPolicy) = "t=$(threshold(p)),c=$(name(constraint(p)))"

struct ScorePolicy <: PolicyType
    scoring::ScoringType
    n::Int # Number of arc to select each iteration  
end 
ScorePolicy() = ScorePolicy(HistoricalEntropyScore(), 1)
hparams(p::ScorePolicy) = "n=$(p.n), s=$(name(p.scoring))" # ,c=$(name(constraint(p)))
typedict(p::PolicyType) = typedict_json(p)

default_policy()::PolicyType = ScorePolicy()

function init!(learner::LearnerType, policy::ScorePolicy)
    return 
end 

function make_actions(state::StateType, learner::LearnerType)
    make_actions(state, policy(learner), learner)
end 

function make_action(state::StateType, policy::PolicyType, learner::LearnerType, object::InstanceObjectType)
    label = make_prediction(state, learner, object)
    constraint = SingleSolutionConstraint(
        state.info["node_uuid"], object.id, label, get_label_type(state.instance)
    )
    AddLazyConstraint(constraint)
end 

#=
function make_action(policy::PolicyType, learner::LearnerType, object::InstanceObjectType, ::SingleSolutionConstraintType)::ActionType
    label = get_most_likely_outcome(learner.stats, object)
    constraint = SingleSolutionConstraint(object, label)
    AddLazyConstraint(constraint)
end 

function make_action(policy::PolicyType, learner::LearnerType, arc::Arc, ::RangeConstraintType)::ActionType
    range = get_consist_gap_range(learner.stats, arc)
    constraint = RangeConstraint(arc.id, Int(range[1]), Int(range[2]))
    AddLazyConstraint(constraint)
end 
=# 

function should_make_action(policy::PolicyType, learner::LearnerType, arc::Arc)::Bool
    prediction_history = learner.history.hash
    OnlineStats.pdf(prediction_history[arc.id], 1) > threshold(policy)  
end 

function make_actions(policy::ThresholdPolicy, learner::LearnerType, net::LapNet)
    actions = ActionType[]
    for arc in train_arcs(net)
        if should_make_action(policy, learner, arc)
            action = make_action(policy, learner, arc)
            push!(actions, action)
        end 
    end 
    return actions 
end 

function make_actions(state::StateType, policy::ScorePolicy, learner::LearnerType)
    actions = ActionType[]
    scores = compute_scores!(state, policy.scoring)
    object_ids = take_top_n(scores, policy.n)

    for object_id in object_ids 
        object = get_object(state.instance, object_id) 
        action = make_action(state, policy, learner, object)
        push!(actions, action)
    end 

    return actions 
end 


function is_optimal_solution_preserved(action::AddLazyConstraint, instance::ProblemInstance)::Bool
    is_solution_included(action.constraint, instance)
end 
