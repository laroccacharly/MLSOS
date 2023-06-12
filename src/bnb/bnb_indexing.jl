function current_index(tree::BnBTree)
    current_index(default_indexer(), tree)
end 

function previous_index(tree::BnBTree)
    current_index(tree) - 1 
end 

function get_nodes_at_index(tree::BnBTree, index::Int)::Array{BnBNode, 1}
    positions = tree.node_position_hash[index]
    BnBNode[tree.nodes[position] for position in positions]
end 

function get_last_node_at_index(tree::BnBTree, index::Int)::BnBNode
    nodes = get_nodes_at_index(tree, index)
    return nodes[end]
end 

function get_first_node_at_index(tree::BnBTree, index::Int)::BnBNode
    nodes = get_nodes_at_index(tree, index)
    return nodes[1]
end 

function update_index!(tree::BnBTree)::BnBTree 
    if ismissing(get(tree.node_position_hash, current_index(tree), missing))
        tree.node_position_hash[current_index(tree)] = Int[] 
    end 
    push!(tree.node_position_hash[current_index(tree)], length(tree.nodes)) 
    return tree 
end 

function current_index(indexer::FloorNodeCount, tree::BnBTree)::Int 
    floor(length(tree.nodes)/indexer.node_count) 
end 

function current_index(indexer::TemporalIndexing, tree::BnBTree)::Int 
    node = get_latest_node(tree)
    floor(get_time(node)/indexer.dt) 
end 

#default_indexer() = FloorNodeCount(5)
default_indexer() = get_value("bnb_indexer")