
# Consists related helper functions
## ground_departure and arrival_ground arcs should have the same consists candidates as the corresponding the train arc. 
function consists(arc::Arc, net::LapNet)::Array{Consist, 1}
    !has_train(arc) && return [] # An arc without a train cannot have consists
    if arc_type(arc) == "ground_departure" 
        outbound_arcs = outbound(net, arc.dst)
        @assert length(outbound_arcs) == 1 
        return consists(outbound_arcs[1], net)
    elseif arc_type(arc) == "arrival_ground" 
        inbound_arcs = inbound(net, arc.src)
        @assert length(inbound_arcs) == 1 
        return consists(inbound_arcs[1], net)
    elseif arc_type(arc) == "train"
        return consist_candidates(arc)
    else
        throw("This arc type is not supported $arc")
    end 
end 
consists_ids(i::Int, net::LapNet)::Array{Int, 1} = id(consists(net.arcs[i], net))

