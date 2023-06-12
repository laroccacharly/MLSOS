struct ContainerLength
    value::Int 
end 
JSON.lower(c::ContainerLength) = c.value 

Base.show(io::IO, i::ContainerLength) = write(io, 
    "$(i.value)"
)

ShortContainerLength() = ContainerLength(20) 
LargeContainerLength() = ContainerLength(53) 

mutable struct Container <: InstanceObjectType
    id::Union{Missing, Int}
    weight::Float64
    cost::Float64
    container_length::ContainerLength
    assigned::Bool 
    info::Dict{Any, Any}
end 
get_id(c::Container) = c.id 

function Base.show(io::IO, a::Vector{Container})
    if length(a) == 0 
        return 
    end 
    Base.show.(a)
end 
Base.show(io::IO, i::Container) = println(io, 
    crayon"white", 
    "Container(id=$(i.id), weight=$(i.weight), length=$(i.container_length), assigned=$(i.assigned ? "✅" : "❌"))" # cost=$(i.cost),
)

get_cost(c::Container) = c.cost 
get_weight(c::Container) = c.weight 
get_length(c::Container) = c.container_length.value 
get_container_length(c::Container)::ContainerLength = c.container_length

convert_weight_to_cost(weight::Float64)::Float64 =  1000*weight

function Container(weight::Float64, container_length::ContainerLength)
    Container(
        missing, 
        weight, 
        convert_weight_to_cost(weight), 
        container_length,
        false,
        Dict() 
    )
end 

function Container(dict::Dict)
    c = Container(dict["weight"], ContainerLength(dict["container_length"]))
    c.id = dict["id"]
    return c 
end 

mutable struct PlatformSlot 
    id::Union{Missing, Int}
    is_bottom::Bool 
    containers::Array{Container, 1}
end 
get_containers(s::PlatformSlot) = s.containers

is_empty(s::PlatformSlot) = length(s.containers) == 0
total_weight(s::PlatformSlot) = is_empty(s) ? 0.0 : sum(get_weight, s.containers)

to_string(i::PlatformSlot) = "Slot(id=$(i.id), is_bottom=$(i.is_bottom))"
Base.show(io::IO, a::Vector{PlatformSlot}) = Base.show.(a)

function Base.show(io::IO, i::PlatformSlot)
    println(io, crayon"red", to_string(i))

    if !is_empty(i)
        Base.show(i.containers)
    end 
end 

PlatformSlot(is_bottom::Bool) = PlatformSlot(missing, is_bottom, Container[])
is_bottom(s::PlatformSlot) = s.is_bottom 
BottomSlot() = PlatformSlot(true)
TopSlot() = PlatformSlot(false)

mutable struct Platform
    id::Union{Missing, Int} 
    position::Union{Missing, Int}  # relative position on the railcar 
    weight_capacity::Float64
    length::Int 
    slots::Array{PlatformSlot, 1}
end 

to_string(i::Platform) = "Platform(id=$(i.id), weight_capacity=$(i.weight_capacity), length=$(i.length))"
Base.show(io::IO, a::Vector{Platform}) = Base.show.(a)
function Base.show(io::IO, i::Platform)
    println(io, crayon"yellow", to_string(i))
    Base.show(i.slots)
end 

get_weight_capacity(p::Platform) = p.weight_capacity 
get_length(p::Platform) = p.length 
get_slots(p::Platform) = p.slots 
get_containers(p::Platform)::Array{Container, 1} = flatten(get_containers.(get_slots(p)))

total_weight(platform::Platform) = sum(get_weight, get_containers(platform))


function Platform(weight_capacity::Float64, length::Int)
    Platform(missing, missing, weight_capacity, length, PlatformSlot[BottomSlot(), TopSlot()])
end 

function SmallPlatform()
    Platform(7.0, 40)
end 

function LargePlatform()
    Platform(7.0, 53)
end 

# Represents how many container of every length can be stored on the platform
mutable struct PlatformLoadingPattern 
    id::Union{Missing, Int}
    dict::Dict{ContainerLength, Int}
end 

function Base.show(io::IO, p::PlatformLoadingPattern)
    println(io, display(p.dict))
    println(io, "Id: ", p.id)
    println(io, "Score: ", get_score(p))
    println(io, "Usage ratio: ", get_usage_ratio(p))
end 

function PlatformLoadingPattern(container_lengths::Array{ContainerLength, 1}, container_counts::Array{Int, 1})
    dict = Dict{ContainerLength, Int}(l => c for (l, c) in zip(container_lengths, container_counts))
    PlatformLoadingPattern(missing, dict)
end 

function get_container_lengths(p::PlatformLoadingPattern)::Array{ContainerLength, 1}
    list = ContainerLength[] 
    for (k,v) in p.dict
        if v == 0 
            continue 
        end 
        for _ in 1:v
            push!(list, k)
        end 
    end 
    return list 
end 

function container_count(pattern::PlatformLoadingPattern, container_length::ContainerLength)::Int
    pattern.dict[container_length]
end 

# Represent the id pattern on each platform of the railcar. 
mutable struct RailcarLoadingPattern
    id::Union{Missing, Int}
    platform_pattern_ids::Array{Int, 1}  
end 

function Base.show(io::IO, p::RailcarLoadingPattern)
    println(io, "Platform ids: ", p.platform_pattern_ids)
    println(io, "Score: ", get_score(p))
    println(io, "Usage ratio: ", get_usage_ratio(p))
    println(io, "Class: ", get_class(p))
end 

function RailcarLoadingPattern(platform_pattern_ids::Array{Int, 1})
    RailcarLoadingPattern(missing, platform_pattern_ids)
end 
platform_count(p::RailcarLoadingPattern)::Int = length(p.platform_pattern_ids)

mutable struct Railcar <: InstanceObjectType
    id::Union{Missing, Int}
    cost::Float64
    platforms::Array{Platform, 1}
    loading_patterns::Union{Missing, Array{RailcarLoadingPattern, 1}}
    assigned::Bool 
    info::Dict{Any, Any}
end 

Base.show(io::IO, a::Vector{Railcar}) = Base.show.(a)
function Base.show(io::IO, i::Railcar)
    println(io, crayon"yellow", "Railcar(id=$(i.id), cost=$(i.cost))")
    Base.show(i.platforms)
end 

get_cost(r::Railcar) = r.cost
get_platforms(r::Railcar) = r.platforms 
get_loading_patterns(r::Railcar) = r.loading_patterns
get_slots(r::Railcar) = get_slots.(get_platforms(r)) |> flatten 

function Railcar(platforms::Array{Platform, 1})
    cost = sum(get_length.(platforms)) # Assuming cost depends on the total length of the railcar. 
    platform_position = 0 
    platforms = map(platforms) do platform 
        platform_position += 1 
        @set platform.position = platform_position
    end 
    Railcar(missing, cost, platforms, missing, false, Dict())
end 

#=
function LargeRailcar()::Railcar 
    platforms = map(1:5) do i 
        LargePlatform() 
    end 
    Railcar(platforms)
end 


function Railcar(dict::Dict)
    if dict["type"] == "large"
        railcar = LargeRailcar()
        railcar.id = dict["id"]
        return railcar 
    else 
        @error "Unknown railcar $dict"
    end  
end 
=# 
mutable struct LppInstance <: ProblemInstance
    id::String
    containers::Array{Container, 1}
    railcars::Array{Railcar, 1}
    info::Dict{String, Any}
    LppInstance(id, containers, railcars) = new(id, containers, railcars, Dict{String, Any}())
end 
get_id(i::LppInstance) = i.id 
get_railcars(instance::LppInstance) = instance.railcars 
get_platforms(instance::LppInstance)::Array{Platform, 1} = flatten(get_platforms.(get_railcars(instance))) 
get_slots(instance::LppInstance)::Array{PlatformSlot, 1}  =  flatten(get_slots.(get_platforms(instance))) 
get_loading_patterns(instance::LppInstance)::Array{RailcarLoadingPattern, 1}  =  flatten(get_loading_patterns.(get_railcars(instance))) 
get_container_lengths(instance::LppInstance) = unique(get_container_length.(get_containers(instance)))

function get_containers(instance::LppInstance; container_length::Union{Missing, ContainerLength}=missing)::Array{Container, 1}
    if ismissing(container_length)
        return instance.containers 
    end 

    filter(c -> c.container_length == container_length, instance.containers)
end     



