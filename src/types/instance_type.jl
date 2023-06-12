# TODO: rename this to LapInstanceDefinition
struct Instance 
    id::String 
    trains::Array{Train, 1}
    spacetime_horizon::SpaceTimeHorizon
    station_ids::Array{Int, 1} # All the stations that could be found in the cercle defined by spacetime_horizon 
    station_position_hash::Dict{Int, Int} # Input: station_id. Output: its index in the array station_ids 
    start_time::DateTime
    end_time::DateTime
end 