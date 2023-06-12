abstract type LocomotiveType end 

struct SimpleLocomotiveType <: LocomotiveType
    id::Int
    hp::Int
    cost::Float64
    SimpleLocomotiveType(id, hp) = new(id, hp, Float64(hp))
end 
Base.:(==)(a::SimpleLocomotiveType, b::SimpleLocomotiveType) = (a.id == b.id)
name(l::LocomotiveType)::String = "loco$(l.hp)"
hp(l::LocomotiveType)::Int = l.hp 

active_cost(type::LocomotiveType) = type.cost * 2
deadhead_cost(type::LocomotiveType) = type.cost
    
function build_locomotive_types()
    df = DataFrame(
        id=[1,2,3,4],
        hp=[4400, 4300, 3200, 2000]
    )
    map(r -> SimpleLocomotiveType(r...), eachrow(df))
end
locomotive_types = build_locomotive_types()
locomotive_types_ids = locomotive_types |> id # sugar 

struct LocomotiveTypeCount
    locomotive_type::LocomotiveType
    count::Int
end 
count(l::LocomotiveTypeCount)::Int = l.count 
hp(l::LocomotiveTypeCount) = l.count * hp(l.locomotive_type)
active_cost(l::LocomotiveTypeCount) = active_cost(l.locomotive_type) * l.count  
deadhead_cost(l::LocomotiveTypeCount) = deadhead_cost(l.locomotive_type) * l.count 