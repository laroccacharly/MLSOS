struct Consist
    id::Int 
    values::Array{LocomotiveTypeCount, 1}
end
function Base.show(io::IO, c::Consist)
    write(io, "Consist(id=$(c.id), $(to_string(c)))")
end
hp(c::Consist) = sum(hp, c.values)
get_counts(c::Consist)::Array{Int, 1} = map(l -> l.count, c.values)
counts(c::Consist) = get_counts(c)
to_string(c::Consist)::String = join(counts(c))
Base.:(==)(a::Consist, b::Consist) = (a.id == b.id)
serealize(c::Consist)::String = to_string(c)
is_consist_empty(c::Consist)::Bool = sum(count, c.values) == 0


struct RelaxedConsist
    locomotive_types::Array{LocomotiveType, 1}
    values::Array{Float64, 1}
end 
to_string(c::RelaxedConsist) = join(map(v -> round(v; digits=2), c.values), ",")
Base.zero(::RelaxedConsist) = RelaxedConsist(locomotive_types, zeros(length(locomotive_types), length(locomotive_types)))  
Base.:(+)(a::RelaxedConsist, b::RelaxedConsist) = RelaxedConsist(a.locomotive_types, (a.values .+ b.values)) 
Base.:(+)(a::Missing, b::RelaxedConsist) = RelaxedConsist(b.locomotive_types, b.values)
Base.:(-)(a::RelaxedConsist, b::RelaxedConsist) = RelaxedConsist(a.locomotive_types, (a.values .- b.values)) 
is_consist_empty(c::RelaxedConsist)::Bool = all(v -> v == 0.0, c.values)
Base.show(io::IO, c::RelaxedConsist) = write(io, to_string(c))
function hp(c::RelaxedConsist) 
    total = 0 
    for id in id(locomotive_types)
        loco_hp = c.locomotive_types[id] |> hp 
        value = c.values[id]
        total += value * loco_hp 
    end 
    return total 
end 

function get_value(c::RelaxedConsist, locomotive_type::LocomotiveType)::Float64
    for (l, v) in zip(c.locomotive_types, c.values)
        if l == locomotive_type
            return v 
        end 
    end 
end 

struct Counts
    values::Array{Int, 1}
end 
Base.iterate(C::Counts, state=1) = state > length(C.values) ? nothing : (C.values[state], state+1)
Base.length(C::Counts) = length(C.values)
Base.:(==)(a::Counts, b::Counts) = (a.values == b.values)
Base.string(c::Counts) = join(c.values)



