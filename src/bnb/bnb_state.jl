

function non_uuid_features(df::DataFrame)::Array{String, 1}
    filter(w -> !occursin("uuid", w), names(df))
end 

function make_bnb_state(nodes::Array{BnBNode, 1})::BnBState
    df = solutions_to_df(nodes)
    if size(df, 1) == 0 
        return EmptyState() 
    end

    data = [] 
    feature_names = non_uuid_features(df)
    for gdf in groupby(df, :train_uuid)
        d = Dict{String, Any}(
            "train_uuid" => gdf[1, :train_uuid],
        ) 
        for feature in feature_names 
            d["mean_$feature"] = mean(gdf[!, feature])
            # We could add those features later 
            #d["min_$feature"] = minimum(gdf[!, feature])
            #d["max_$feature"] = maximum(gdf[!, feature])
        end 
        d["local_entropy"] = get_entropy(gdf[!, :slack])
        push!(data, d)
    end 
    FullState(length(nodes), to_df_from_dict(data)) 
end 

function merge_states(s1::FullState, s2::FullState)::BnBState
    feature_names = non_uuid_features(s1.df)
    new_node_count = s1.node_count + s2.node_count
    data = []

    for (row1, row2) in zip(eachrow(s1.df), eachrow(s2.df))
        @assert row1.train_uuid == row2.train_uuid 
        d = Dict{String, Any}(
            "train_uuid" => row1[:train_uuid],
        ) 
        for feature in feature_names 
            # Weighted mean 
            d[feature] = (row1[feature] * s1.node_count + row2[feature] * s2.node_count)/(new_node_count)
        end 
        push!(data, d)
    end 
    FullState(new_node_count, to_df_from_dict(data)) 
end 

function merge_states(s1::EmptyState, s2::FullState)::BnBState
    return s2 
end 

function merge_states(s1::FullState, s2::EmptyState)::BnBState
    return s1
end 

function merge_states(s1::EmptyState, s2::EmptyState)::BnBState
    return s1
end 