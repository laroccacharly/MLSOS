abstract type NodeData end 
struct LapNodeData <: NodeData
    type::String
    station_id::Int
    timestamp::Dates.DateTime
    is_ground::Bool
end

struct FcnNodeData <: NodeData
    type::String
    supply::Float64
end

function FcnNodeData(supply::Number)
    type_name = ""
    if supply > 0 
        type_name = "source"
    elseif supply < 0 
        type_name = "sink"
    else 
        type_name = "intermidiate"
    end 
    FcnNodeData(type_name, supply)
end 

struct Node 
    id::Int
    data::NodeData
end 
get_supply(node::Node) = node.data.supply
timestamp(node::Node) = node.data.timestamp 
is_ground(node::Node) = node.data.is_ground
station_id(node::Node) = node.data.station_id
coordinates(node::Node) = coordinates(node.data.station_id)
struct TrainNodes
    ground_departure::NodeData
    departure::NodeData 
    arrival::NodeData 
    ground_arrival::NodeData
end 