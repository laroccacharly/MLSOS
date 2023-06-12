
struct TopK <: SelectionStrategy 
    value::Int 
end 
Base.string(s::TopK) = name(s)
name(s::TopK) = "TopK(k=$(s.value))"
function select(strategy::TopK, prediction, consists)
    nelements = min(length(consists), strategy.value)
    selected_consists = consists[sortperm(prediction, rev=true)[1:nelements]]
    selected_consists
end 

# Select consists up to a confidence point 
struct Confidence <: SelectionStrategy 
    value::Float32 
end 
Base.string(s::Confidence) = name(s)
name(s::Confidence) = "Confidence(s=$(s.value))"

function select(strategy::Confidence, prediction, consists)::Array{Consist, 1} 
    @assert length(prediction) == length(consists)
    prediction = trysoftmax(prediction)
    sorted_indexes = sortperm(prediction, rev=true)
    accumulator = 0 
    candidates = []
    nconsists  = 0 
    while accumulator < strategy.value && nconsists < length(consists) # sum over prediction wont be 1 because we only consider the predictions for possible consists. 
        nconsists += 1 
        push!(candidates, consists[sorted_indexes[nconsists]])
        accumulator += prediction[sorted_indexes[nconsists]]
    end 
    return candidates 
end 


struct RandomTopK <: SelectionStrategy 
    value::Int
end 
name(s::RandomTopK) = "RandomTopK(k=$(s.value))"
build_random_permutation(size::Int) = randperm(size) 

prediction_history = Dict{Array{Number, 1}, Array{Number, 1}}()
function select(strategy::RandomTopK, prediction, consists)
    random_permutation = get(prediction_history, prediction, missing)
    if ismissing(random_permutation)
        random_permutation = build_random_permutation(length(consists))
        prediction_history[prediction] = random_permutation
    end 
    nelements = min(length(consists), strategy.value)

    consists[random_permutation][1:nelements]
end 

value(s::SelectionStrategy) = s.value 

struct MonteCarlo <: SelectionStrategy 
    value::Int 
end 
name(s::MonteCarlo) = "MonteCarlo(k=$(s.value))"
Base.string(s::MonteCarlo) = name(s)

function select(strategy::MonteCarlo, prediction, consists)::Array{Consist, 1}
    sample(consists, Weights(Float32.(prediction)), strategy.value) |> unique 
end 

default_strategy = TopK(1)
function set_default_selection_strategy!(s::SelectionStrategy)
    global default_strategy = s 
end 

select(prediction, consists) = select(default_strategy, prediction, consists)
    

