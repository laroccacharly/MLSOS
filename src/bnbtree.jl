include("bnb/bnb_state.jl")
include("bnb/bnb_indexing.jl")
include("bnb/bnb_stats.jl")
include("bnb/bnb_metrics.jl")


get_indexes(tree::BnBTree) = keys(tree.node_position_hash) |> collect |> sort 

function add_node!(tree::BnBTree, node::BnBNode)
    if ismissing(tree.cplex_init_time)
        tree.cplex_init_time = node.cplex_info["time"]
    end 
    # Shifting time so it is relative to the time of the first node
    node.cplex_info["time"] = node.cplex_info["time"] - tree.cplex_init_time

    if node.cb_context_id == CPLEX.CPX_CALLBACKCONTEXT_CANDIDATE
        tree.number_candidates += 1 
    end 
    push!(tree.nodes, node)
    update_index!(tree)
end 
to_df(tree::BnBTree) = to_df_from_dict(get_cplex_info.(tree.nodes))

function find_node(tree::BnBTree, node_uuid::String)
    for node in tree.nodes
        if node.id == node_uuid
            return node
        end 
    end 
    error("Node not found")
end 


function build_state_at_index(tree::BnBTree, index::Int)::BnBState 
    make_bnb_state(get_nodes_at_index(tree, index))
end 

# Recusive algorithm. The state at a given index is built from the previous state and the nodes at that index. 
function build_cumulative_state_at_index(tree::BnBTree, index::Int)::BnBState 
    @info "build_state_at_index $index"
    if index == 0
        return make_bnb_state(get_nodes_at_index(tree, index))
    end 
    previous_state = get_state_at_index(tree, index - 1)
    state = make_bnb_state(get_nodes_at_index(tree, index))
    merge_states(state, previous_state)
end 

# The state is cached for efficiency. 
function get_state_at_index(tree::BnBTree, index::Int)::BnBState
    if ismissing(get(tree.state_cache, index, missing))
        tree.state_cache[index] = build_state_at_index(tree, index)
    end 

    tree.state_cache[index]
end

function get_features_at_index(tree::BnBTree, index::Int)::DataFrame
    state = get_state_at_index(tree, index)
    state_features = state.df
    return state_features
end 

function show_info(tree::BnBTree, info)
    d = []
    for node in tree.nodes 
        push!(d, 
            Dict(
                "context" => node.cplex_info["context"],
                info => node.cplex_info[info]
            )
        )
    end 
    @show to_df_from_dict(d)
end 


function candidate_nodes(tree::BnBTree)::Array{BnBNode, 1}
    nodes = BnBNode[]
    for node in tree.nodes 
        if node.cb_context_id == CPLEX.CPX_CALLBACKCONTEXT_CANDIDATE # && (node.cplex_info["found_sol"] == 1)
            push!(nodes, node)
        end 
    end 
    if length(nodes) == 0 
        @warn "No candidates in tree"
        @show length(tree.nodes)
        # show_info(tree, "best_sol")
    end 
    return nodes 
end 

function lp_nodes(tree::BnBTree)::Array{BnBNode, 1}
    filter(n -> is_lp(n), tree.nodes)
end     

function best_candidate_node(tree::BnBTree)::BnBNode
    nodes = candidate_nodes(tree)
    if length(nodes) == 0 
        @warn "No candidates node found. Using nodes with solution instead."
        nodes_with_solution(tree)[end]
    else 
        return nodes[end]
    end 
end 

get_latest_node(tree::BnBTree)::BnBNode = tree.nodes[end]

function get_solution_row(node::BnBNode, object_id::Int)
    node.solution_df[object_id, :]
end 

function solutions_to_df(nodes::Array{BnBNode, 1})::DataFrame 
    df = DataFrame() 
    for node in nodes |> select_nodes_with_solution
        push_df!(df, node.solution_df) 
    end 
    return df 
end 

function select_nodes_with_solution(nodes::Array{BnBNode, 1})::Array{BnBNode, 1}
    filter(n -> !ismissing(n.solution_df), nodes)
end 

function nodes_with_solution(tree::BnBTree)::Array{BnBNode, 1}
    tree.nodes |> select_nodes_with_solution
end 

function solutions_to_df(tree::BnBTree)::DataFrame 
    nodes = nodes_with_solution(tree)
    solutions_to_df(nodes)
end 

include("bnb/bnb_plots.jl")