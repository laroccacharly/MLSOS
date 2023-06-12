abstract type PerturbationType end 

struct PerturbedScenario <: ProblemScenario
    scenario::ProblemScenario
    perturbation::PerturbationType
end 
is_perturbed(::PerturbedScenario) = true 
is_perturbed(::ProblemScenario) = false 

function Base.show(io::IO, i::PerturbedScenario) 
    Base.show(io, i.scenario)
    Base.show(io, i.perturbation)
end 

function Base.show(io::IO, i::PerturbationType) 
    println(io, "Perturbation: $(to_string(i))") 
end 

get_formulation(p::PerturbedScenario) = get_formulation(p.scenario)

function typedict(s::PerturbedScenario)
    merge(
        typedict(s.scenario),
        typedict(s.perturbation)
    )
end 

function to_string(s::PerturbedScenario)
    to_string(s.scenario) * to_string(s.perturbation)
end 
