
function TrainingCallbackState(result::SolverResultsType; skip_training::Bool=false)
    tree = get_tree(result)
    instance = get_instance(result)

    TrainingCallbackState(
        instance,
        tree,
        BnBStats(instance), 
        LazyConstraintType[],
        result,
        Dict(
            "skip_training" => skip_training, 
            "current_node_index" => 0 
        )
    )
end 

# TODO: This can fail if algo does have these settings 
function set_algorithm_settings!(state::StateType, algo::MIPAlgorithm)
    state.info["scoring_type"] = algo.scoring_type
    state.info["fixing_ratio"] = algo.fixing_ratio
    state.info["scheduler"] = algo.scheduler
end 

get_scoring_type(state::StateType) = get(state.info, "scoring_type", HistoricalEntropyScore())
get_fixing_ratio(state::StateType) = get(state.info, "fixing_ratio", 0.2)
get_scheduler(state::StateType) = get(state.info, "scheduler", OneTimeScheduler(5))

function compute_scores!(state::StateType)
    compute_scores!(state, get_scoring_type(state))
end 

function compute_number_of_objects_to_select(state::StateType)
    objects = get_objects(state.instance)
    number_objects = length(objects)
    fixing_ratio = get_fixing_ratio(state)
    selected_count = ceil(number_objects * fixing_ratio) |> Int
    return selected_count
end 

function select_objects_to_constraint(state::StateType)
    objects = get_objects(state.instance)
    scores = compute_scores!(state)
    n = compute_number_of_objects_to_select(state)
    object_ids = take_top_n(scores, n)
    [get_object(state.instance, id) for id in object_ids]
end 


function skip_training(state::TrainingCallbackState)
    state.info["skip_training"]
end 

function get_constrained_object_ids(state::TrainingCallbackState)
    [] 
end 

function get_next_node!(state::StateType)::BnBNode
    state.info["current_node_index"] += 1 
    node = get_current_node(state)
    state.info["node_uuid"] = node.id 
    return node 
end 

function get_nodes(state::StateType)
    state.tree.nodes
end 

function get_current_node(state::StateType)::BnBNode
    get_nodes(state)[state.info["current_node_index"]]
end 

function get_current_node_index(state::StateType)
    state.info["current_node_index"]
end 

function done_iterating(state::StateType)
    state.info["current_node_index"] == length(get_nodes(state))
end 

function should_evaluate(state::StateType)
    has_solution(get_current_node(state))
    # state.info["current_node_index"] % 10 == 0 
end 