struct StationsDB
    df::DataFrame
    stations_hash::Dict{String, Int}
end 

struct Station 
    id::Int 
    name::String 
    state::String 
    position::Coordinates 
end 
