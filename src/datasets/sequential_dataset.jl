struct SequentialDataset <: DatasetType
    time::Dates.DateTime
    direction::Direction 
    number_instances::Int 
    instance_radius::Int 
end 

instance_duration(d::SequentialDataset) = Week(1)

function get_spacetime_horizons(d::SequentialDataset)::Array{SpaceTimeHorizon, 1}
    if d.direction == Forward() 
        first_st = SpaceTimeHorizon(
            d.time,
            d.time + instance_duration(d),
            default_coordinates(),
            Miles(d.instance_radius)
        )
    else 
        first_st = SpaceTimeHorizon(
            d.time - instance_duration(d),
            d.time,
            default_coordinates(),
            Miles(d.instance_radius)
        )
    end 
    st = first_st |> deepcopy
    following_st = SpaceTimeHorizon[]
    for i in 1:d.number_instances-1
        new_st = move!(d.direction, st)
        st = new_st
        push!(following_st, new_st)
    end 

    return SpaceTimeHorizon[first_st, following_st...]
end 



#= 
function build_sequential_spacetime_horizons(time::Dates.DateTime, direction::Forward, quantity::Int, radius::Int)
    start_time = time 
    map(1:quantity) do 
        st = build_spacetime_horizon_from_start_time(start_time, radius)
        start_time += test_instance_nhours() 
        st 
    end 
end 

function build_sequential_spacetime_horizons(time::Dates.DateTime, direction::Backward, quantity::Int, radius::Int)
    end_time = time 
    map(1:quantity) do 
        st = build_spacetime_horizon_from_end_time(end_time, radius)
        end_time -= test_instance_nhours() 
        st 
    end 
end 
=# 

