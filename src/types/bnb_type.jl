struct BnBNode
    id::String 
    cb_context_id::Clong 
    cplex_info::Dict{String, Any}
    solution_df::Union{Missing, DataFrame} 
end 
get_cplex_info(node::BnBNode) = node.cplex_info
get_info(node::BnBNode, key::String) = node.cplex_info[key]
get_labels(node::BnBNode)::Array{Number, 1} = node.solution_df[!, :consist_id]
is_lp(node::BnBNode)::Bool = node.cb_context_id == CPLEX.CPX_CALLBACKCONTEXT_RELAXATION
function get_slack(node::BnBNode, train_arc_id::Int)::Int
    node.solution_df[train_arc_id, :slack]
end 
best_objective_value(n::BnBNode) = n.cplex_info["best_sol"]
function is_objective_value_valid(n::BnBNode)::Bool
    best_objective_value(n) != 0 && !is_inf(best_objective_value(n))
end 

get_time(n::BnBNode) = n.cplex_info["time"]
has_solution(n::BnBNode)::Bool = !ismissing(n.solution_df)
number_of_trains(n::BnBNode)::Int = size(n.solution_df, 1)
# Summerise all of the useful from a collection of BnBNodes. 
# This is used to build features related to the current state of the BnBTree 
abstract type BnBState end

struct FullState <: BnBState
    node_count::Int 
    df::DataFrame
end 

struct EmptyState <: BnBState
end 


mutable struct BnBTree
    nodes::Array{BnBNode, 1}
    number_candidates::Int
    cplex_init_time::Union{Missing, Number} 
    node_position_hash::Dict{Int, Array{Int, 1}} # index => position of nodes at index
    state_cache::Dict{Int, BnBState}
    BnBTree() = new(BnBNode[], 0, missing, Dict(), Dict())
end 
JSON.lower(b::BnBTree) = nothing

# Question: How can we create a layer of abstraction on top of 
# BnBTree and place nodes in groups? We use indexing to access a 
# specific group of nodes. 
abstract type BnBIndexing end

# The index of a node is the current number of nodes divided by some constant. 
struct FloorNodeCount <: BnBIndexing
    node_count::Int 
end 

# Indexing using a discrete temporal step (dt) 
struct TemporalIndexing <: BnBIndexing
    dt::Float64
end 