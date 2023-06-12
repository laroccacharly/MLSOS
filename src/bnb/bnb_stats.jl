# Question: How can we track the solution space of for each object in the instance. 

mutable struct BnBStats <: StatisticsType
    hash::Dict{Int, Any} # id => statistics 
end 

function init_bnb_stats()
    Series(Mean(), Variance(), Extrema(), CountMap(Int)) |> deepcopy
end 

function BnBStats(instance::ProblemInstance)
    hash = Dict{Int, Any}()
    for object in get_objects(instance)
        hash[object.id] = init_bnb_stats()
    end 
    BnBStats(hash)
end 

function to_vec(stats)
    t = OnlineStats.value(stats)
    [t[1], t[2], t[3].min, t[3].max]'
end 

function to_dict(stats::BnBStats, object::InstanceObjectType)
    o = stats.hash[object.id]

    Dict(
        "mean" => OnlineStats.value(o.stats[1]),
        "variance" => OnlineStats.value(o.stats[2]), 
        "get_most_likely_label" => get_most_likely_label(stats, object),
    )
end 

function get_stats(stats::BnBStats, object::InstanceObjectType, instance::ProblemInstance)
    get_stats(stats, object)   
end 

function get_stats(stats::BnBStats, object::InstanceObjectType)
    stats.hash[object.id] |> to_vec
end 

function get_count_map(stats::BnBStats, object::InstanceObjectType)
    o = stats.hash[object.id]
    cm = o.stats[4]
    return cm 
end 

function get_number_of_nodes_with_solution(stats::BnBStats)::Int 
    # Counting the number of samples in CountMap
    o = stats.hash[keys(stats.hash) |> collect |> first]
    cm = o.stats[4]
    OnlineStats.values(cm) |> sum
end 

function get_label_range(stats::BnBStats, object::InstanceObjectType)
    o = stats.hash[object.id]
    t = OnlineStats.value(o)
    (t[3].min, t[3].max)
end 

function get_most_likely_label(stats::BnBStats, object::InstanceObjectType)::Int
    cm = get_count_map(stats, object)
    collect(keys(cm))[argmax(OnlineStats.probs(cm))]
end 

function get_solution_hash_for_label_type(solution_df::DataFrame, label_type::LabelType)
    df = solution_df[!, [get_index_sym(label_type), get_symbol(label_type)]] |> unique 
    hash = Dict() 
    for row in eachrow(df)
        hash[row[get_index_sym(label_type)]] = row[get_symbol(label_type)]
    end 
    return hash 
end 


function update!(stats::BnBStats, node::BnBNode, instance::ProblemInstance)
    if !has_solution(node)
        return stats 
    end 

    hash = get_solution_hash_for_label_type(node.solution_df, get_label_type(instance))
    # @show hash 
    for (index, object) in enumerate(get_objects(instance))
        OnlineStats.fit!(stats.hash[object.id], get(hash, object.id, 0))
    end  

    return stats 
end 


