struct PredictedStabilityScore <: ScoringType 
end 
name(s::PredictedStabilityScore) = "predicted_stability"
JSON.lower(s::ScoringType) = name(s)

struct Scores <: ScoresType 
    scores::Dict{Int, Number} # id -> score 
    sorted::Array{Int, 1} # High to low id 
end 

function Base.show(io::IO, scores::Scores)
    top_n = 3 
    ids = take_top_n(scores, top_n)
    dict = Dict([i => scores.scores[i] for i in ids])
    println(io, "Scores for top $top_n objects")
    println(io, display(dict))
end 

function Scores(scores::Dict{Int, Number})
    tuples = sort(collect(scores), by=x->x[2], rev=true)
    sorted = Int[t[1] for t in tuples]
    Scores(scores, sorted) 
end 

function take_top_n(scores::ScoresType, n::Int)::Array{Int, 1}
    if length(scores.sorted) < n 
        @warn "Trying to collect $n while only $(length(scores.sorted)) is available."
        return scores.sorted 
    end 
    scores.sorted[1:n]
end 

function entropy_from_probability(probs)
    - sum(probs .* log2.(probs))
end 

function compute_scores!(state::StateType, scoring_type::ScoringType)::ScoresType
    scores = Dict{Int, Number}() 
    for object in get_objects(state.instance)
        if object.id in get_constrained_object_ids(state)
            continue 
        end 
        score = compute_score!(state, object, scoring_type)
        scores[object.id] = score  
    end 
    return Scores(scores)
end 

function compute_score!(state::StateType, object::InstanceObjectType, ::HistoricalEntropyScore)
    cm = get_count_map(get_stats(state), object)
    e = entropy_from_probability(OnlineStats.probs(cm))
    return - e # minus entropy because we want to maximize the score.  
end 

function get_entropy(state::StateType, object::InstanceObjectType)
    cm = get_count_map(get_stats(state), object)
    e = entropy_from_probability(OnlineStats.probs(cm))
    return e
end

function compute_score!(state::StateType, object::InstanceObjectType, ::RandomScore)
    rand()
end 

function compute_score!(state::StateType, object::InstanceObjectType, ::PredictedStabilityScore)
    @error "TDB"
    cm = get_count_map(state.history, object)
    p = OnlineStats.pdf(cm, 1) # probability that object is stable  
    return p
end 

