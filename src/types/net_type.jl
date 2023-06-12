include("node_type.jl")
include("arc_type.jl")

@enum FlowType begin
    # same_direction # used for 0th neighboor 
    origin_out
    origin_in
    destination_out
    destination_in 
end 

struct Neighbour
    arc_id::Int 
    degree::Int # is it a 1st neighboor or 2nd neighboor, etc. 
    flow_type::FlowType # how does it relate to the source arc 
end     

mutable struct LapNet <: ProblemInstance
    graph::MetaDiGraph
    nodes::Array{Node, 1}
    arcs::Array{Arc, 1}
    hashmap_nodes::Dict{String, Array{Node, 1}}
    hashmap_arcs::Dict{String, Array{Arc, 1}}
    hashmap_neighbourhood::Dict{Int, Array{Neighbour, 1}}
    hashmap_trains::Dict{String, Int}
    hashmap_station_features::Dict{Int, Array{Tuple{String, Train}, 1}}
    instance::Instance 
end 
init_spacetime_network(instance::Instance) = LapNet(
    MetaDiGraph(0), 
    [], 
    [], 
    Dict(), 
    Dict(), 
    Dict(), 
    Dict(),  
    Dict(), 
    instance,
)
Base.iterate(net::LapNet, state = 1) = state == 2 ? nothing : (net, state + 1) 
Base.length(net::LapNet) = 1 
to_string(net::LapNet) = "LapNet(ntrains=$(length(train_arcs(net))))" 
Base.show(io::IO, net::LapNet) = write(io, to_string(net))
get_spacetime_horizon(net::LapNet)::SpaceTimeHorizon = net.instance.spacetime_horizon

start_time(net::LapNet)::Dates.DateTime = net.instance.start_time
end_time(net::LapNet)::Dates.DateTime = net.instance.end_time
duration(net::LapNet)::Period = end_time(net) - start_time(net)