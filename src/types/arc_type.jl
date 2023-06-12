struct ArcSolution 
    active_consist::Consist
    deadhead_consist::Consist
end 
active_hp(sol::ArcSolution) = hp(sol.active_consist) 
hp(sol::ArcSolution) = active_hp(sol) + hp(sol.deadhead_consist) 
active_cost(sol::ArcSolution) = active_cost(sol.active_consist)
deadhead_cost(sol::ArcSolution) = deadhead_cost(sol.deadhead_consist)

struct ArcRelaxedSolution 
    active_consist::RelaxedConsist
    deadhead_consist::RelaxedConsist
end 
accumulate(sol::ArcRelaxedSolution) = sum(sol.active_consist.values) + sum(sol.deadhead_consist.values)
active_hp(sol::ArcRelaxedSolution) = hp(sol.active_consist)
hp(sol::ArcRelaxedSolution) = active_hp(sol) + hp(sol.deadhead_consist)
active_cost(sol::ArcRelaxedSolution) = active_cost(sol.active_consist)
deadhead_cost(sol::ArcRelaxedSolution) = deadhead_cost(sol.deadhead_consist)

Base.show(io::IO, s::ArcRelaxedSolution) = write(io, "A: $(s.active_consist) D: $(s.deadhead_consist), HP: $(hp(s)) ")

abstract type ArcData end 
mutable struct LapArcData <: ArcData
    type::String
    train_uuid::Union{Missing, String}
    solution::Union{Missing, ArcSolution}
    relaxed_solution::Union{Missing, ArcRelaxedSolution}
    label::Dict{LabelType, Number}
    consist_candidates::Union{Missing, Array{Consist, 1}} # to be used by the MIP
    LapArcData(type::String, train) = new(type, train, missing, missing, Dict{LabelType, Number}(), missing)
end 
Base.show(io::IO, d::LapArcData) =  write(io, "Data: type: $(d.type), label: $(d.label), solution: $(d.solution)")

mutable struct FcnArcData <: ArcData
    fixed_cost::Float64
    variable_cost::Float64
    capacity::Float64
    label::Dict{LabelType, Number}
    FcnArcData(f, v, c) = new(f, v, c, Dict())
end 

struct Arc <: InstanceObjectType
    id::Int
    src::Node
    dst::Node
    data::ArcData
end 
has_train(arc::Arc)::Bool = isa(arc.data.train_uuid, String)
required_horsepower(a::Arc, net) = get_train(a, net) |> (t -> t.required_horsepower)
has_solution(a::Arc)::Bool = isa(a.data.solution, ArcSolution) 
has_relaxed_solution(a::Arc)::Bool = isa(a.data.relaxed_solution, ArcRelaxedSolution)
get_train(arc::Arc, net)::Train = has_train(arc) ? net.instance.trains[net.hashmap_trains[arc.data.train_uuid]] : error("Cannot get the train of arc $arc")
active_consist(arc::Arc)::Consist = has_solution(arc) ? arc.data.solution.active_consist : error("This arc doesn't have a solution $arc")
arc_type(arc::Arc)::String = arc.data.type
is_deadhead_empty(arc::Arc)::Bool = arc.data.solution.deadhead_consist |> is_consist_empty
is_relaxed_deadhead_empty(arc::Arc)::Bool = arc.data.relaxed_solution.deadhead_consist |> is_consist_empty
Base.show(io::IO, arc::Arc) = write(io, "Arc($(arc.src.id) -- $(arc.dst.id), $(arc.data)")
solution(arc::Arc)::ArcSolution = has_solution(arc) ? arc.data.solution : error("arc $arc has no solution")
relaxed_solution(arc::Arc)::ArcRelaxedSolution = has_relaxed_solution(arc) ? arc.data.relaxed_solution : error("This arc does not have a relaxed solution $arc")
distance_origin_destination(arc::Arc)::Miles = distance(station_id(arc.src), station_id(arc.dst)) 
Base.isequal(a1::Arc, a2::Arc)::Bool = a1.id == a2.id 
value_to_sort_by(arc::Arc) = accumulate(relaxed_solution(arc))
consist_candidates(arc::Arc)::Array{Consist, 1} = ismissing(arc.data.consist_candidates) ? error("candidates missing on arc") : arc.data.consist_candidates
duration(arc::Arc)::Period = timestamp(arc.dst) - timestamp(arc.src)
set_label!(arc::Arc, label_type::LabelType, value) = arc.data.label[label_type] = value
get_fixed_cost(arc::Arc) = arc.data.fixed_cost 
get_variable_cost(arc::Arc) = arc.data.variable_cost 
get_capacity(arc::Arc) = arc.data.capacity 