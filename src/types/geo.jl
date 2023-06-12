struct Coordinates 
    lat::Float64
    lon::Float64 
end 
lon(c::Coordinates)::Float64 = c.lon
lat(c::Coordinates)::Float64 = c.lat
JSON.lower(c::Coordinates) = "($(c.lon), $(c.lat))"
default_coordinates()::Coordinates = Coordinates(45.587446, -73.699129) # Montreal 

struct Miles
    value::Float64
end     
Base.:(<)(x1::Miles, x2::Miles) = (x1.value < x2.value)
Base.isless(x1::Miles, x2::Miles) = x1 < x2 
value(x::Miles) = x.value 
Base.string(a::Miles) = "$(a.value) miles"
JSON.lower(a::Miles) = a.value

# Miles per hour 
struct Speed
    value::Float64
end 
Base.:(/)(x::Miles, s::Speed)::Millisecond = Millisecond(floor((x.value / s.value) * 3600 * 1000)) # Converting hours to Millisecond
average_speed = Speed(35) 

const earth_radius_miles = 3959 
function distance(x1::Coordinates, x2::Coordinates)::Miles 
    value = haversine((x1.lat, x1. lon), (x2.lat, x2.lon), earth_radius_miles)
    return Miles(value)
end 

struct SpaceTimeHorizon 
    start_time::DateTime
    end_time::DateTime
    center_point::Coordinates 
    radius::Miles
end 

get_duration(st::SpaceTimeHorizon) = st.end_time - st.start_time

function typedict(st::SpaceTimeHorizon)
    Dict{String, Any}(
        "start_time" => time_to_string(st.start_time), 
        "end_time" => time_to_string(st.end_time), 
        "lon" => lon(st.center_point), 
        "lat" => lat(st.center_point), 
        "radius" => value(st.radius), 
    )
end 

function SpaceTimeHorizon(dict::Dict)
    SpaceTimeHorizon(
        to_datetime(dict["start_time"]), 
        to_datetime(dict["end_time"]), 
        Coordinates(dict["lat"], dict["lon"]), 
        Miles(dict["radius"])
    )
end 

function build_spacetime_horizon_from_end_time(end_time::Dates.DateTime, radius::Int)::SpaceTimeHorizon
    start_time = end_time - test_instance_nhours() 
    SpaceTimeHorizon(
        start_time,
        end_time,
        default_coordinates(), 
        Miles(radius)
    )
end 

function build_spacetime_horizon_from_start_time(start_time::Dates.DateTime, radius::Int)::SpaceTimeHorizon
    end_time = start_time + test_instance_nhours() 
    SpaceTimeHorizon(
        start_time,
        end_time,
        default_coordinates(), 
        Miles(radius)
    )
end 


abstract type Direction end
struct Forward <: Direction end
struct Backward <: Direction end 

function move!(direction::Forward, st::SpaceTimeHorizon; duration=get_duration(st))::SpaceTimeHorizon
    new_st = st |> deepcopy
    new_st = @set new_st.start_time = st.start_time + duration 
    new_st = @set new_st.end_time = st.end_time + duration 
    return new_st 
end 

function move!(direction::Backward, st::SpaceTimeHorizon; duration=get_duration(st))::SpaceTimeHorizon
    new_st = st |> deepcopy
    new_st = @set new_st.start_time = st.start_time - duration 
    new_st = @set new_st.end_time = st.end_time - duration 
    return new_st 
end 

# This is used to id the instance. 
function to_string(st::SpaceTimeHorizon)::String 
    dict = typedict(st)
    start_time_string = dict["start_time"]
    end_time_string = dict["end_time"]
    radius_string = dict["radius"] |> Base.string 

    return "$(start_time_string)_$(end_time_string)_$radius_string"
end 
