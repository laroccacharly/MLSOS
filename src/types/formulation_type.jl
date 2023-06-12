abstract type Formulation end 
# LAP
struct ConsistBased <: Formulation end 
struct LocomotiveBased <: Formulation 
    relaxed::Bool 
    LocomotiveBased(;relaxed=true) = new(relaxed)
end   
is_relaxed(formulation::LocomotiveBased)::Bool = formulation.relaxed
is_relaxed(f::ConsistBased) = false 
Base.string(f::ConsistBased) = "consist_based"
Base.string(f::LocomotiveBased) = "locomotive_based"
JSON.lower(f::Formulation) = string(f)

function from_string(s::String)::Formulation
    if s == string(ConsistBased())
        return ConsistBased() 
    else 
        return LocomotiveBased() 
    end 
end

# LPP 
struct OriginalFormulation <: Formulation end 
Base.string(f::OriginalFormulation) = "original_formulation"
struct ReducedFormulation <: Formulation end 
Base.string(f::ReducedFormulation) = "reduced_formulation"
