softmax(x) = exp.(x) ./ sum(exp.(x))
rand_id() = split(string(uuid4()), "-")[1] |> string 
myreaddir(path) = readdir(path) |> (e -> filter(r -> !occursin("DS_Store", r), e))
remove_spaces(s::String)::String = s |> strip |> string 
remove_spaces(s) = s 
date_format_string = "dd/mm/yyyy HH:MM:SS"
date_format = Dates.DateFormat(date_format_string) ;
function to_datetime(s::AbstractString)::Union{Missing, DateTime}
    length(s) == 0 && return missing 
    splitted = split(s, ".")[1]
    Dates.DateTime(splitted, date_format)
end
to_datetime(string::Missing) = missing
to_datetime(date::DateTime) = date
to_datetime(x) = convert(Dates.DateTime, x)
time_to_string(t::DateTime)::String = Dates.format(t,date_format_string)
JSON.lower(t::Dates.DateTime) = time_to_string(t)

function nhours(p::Period)::Int 
    try 
        h = Hour(p)
        return h.value 
    catch ex 
        @warn ex 
        error("Could not convert period $p to hours")
    end 
end 
add_id(df) = @transform(df, :id= [i for i in 1:size(df, 1)])
id(x) = getfield.(x, :id)
flatten(x) = reduce(vcat, x)
typedict(x) = Dict(fn=>getfield(x, fn) for fn ∈ fieldnames(typeof(x)))
merge_syms(a::Symbol, b::Symbol)::Symbol = Symbol(string(a) * string(b))
is_inf(number)::Bool =  number > 1e11 
typedict_json(object) = JSON.json(object) |> JSON.parse 
gentup(struct_T) = NamedTuple{( fieldnames(struct_T)...,), Tuple{(fieldtype(struct_T,i) for i=1:fieldcount(struct_T))...}}

@generated function to_named_tuple_generated(x)
           nt = Expr(:quote, gentup(x))
           tup = Expr(:tuple)
           for i=1:fieldcount(x)
               push!(tup.args, :(getfield(x, $i)) )
           end
           return :($nt($tup))
end

function trymkdir(path::String)::String 
    try 
        if !isdir(path)
            @info "Creating path $path"
            mkpath(path)
        end 
    catch 
        
    end 
    path 
end 

function replace_nan(x)
    for i = eachindex(x)
        if isnan(x[i])
            x[i] = 0.0
        end
    end
    x 
end

function push_df!(df::DataFrame, df2::DataFrame)::DataFrame 
    for row in eachrow(df2)
        push!(df, row)
    end 
    return df 
end 

function dfrow_to_dict(row::DataFrameRow)::Dict 
    Dict(names(row) .=> values(row))
end 

function to_df_named_tuples(arr)
    try
        T = typeof(arr[1])
        DataFrame(T[a for a in arr])
    catch ex 
        @warn ex 
        @show length(arr)
        @error "Could not combine tuples to make a dataframe."
    end 
end 

function to_df(array)::DataFrame 
    if isa(array[1], NamedTuple)
        return to_df_named_tuples(array)
    else 
        return DataFrame([to_named_tuple_generated(x) for x in array])
    end 
end

function filter_col_names(df::DataFrame, arr_str::Array{String, 1})
    name_lists = map(arr_str) do str 
        filter(n -> occursin(str, n), names(df))
    end         
    name_list = vcat(name_lists...)
    DataFrames.select(df, name_list)
end    

function to_df_from_dict(arr; json_fallback=false)
    rows = [] 
    types_dictionary = Dict()
    a1 = arr[1]
    for (k, v) in a1
        if typeof(v) isa Number
            types_dictionary[k] = Float64
        else 
            types_dictionary[k] = typeof(v)
        end
    end
    for d in arr
        symbols = [] 
        values = []
        for (k, v) in d
            if types_dictionary[k] != typeof(v)
                try 
                    v = convert(types_dictionary[k], v)
                catch ex 
                    @warn ex
                    @warn "Could not convert to $(types_dictionary[k]), $k, $v"
                    @warn "Converting to $(NaN)"
                    v = NaN
                end
            end
            push!(symbols, Symbol(k)); push!(values, v)
        end 

        push!(rows, NamedTuple{(symbols...,)}((values...,))) 
    end 
    try 
        return to_df(rows)
    catch ex 
        if json_fallback
            @warn ex
            @warn "Could not convert to dataframe, trying json fallback"
            json_str = JSON.json(arr)
            json_arr = JSON.parse(json_str)
            return json_arr
        else 
            @error ex
        end 
    end
end     

function save_json(object, name::String, path::String)
    trymkdir(path)
    json_str = JSON.json(object, 4)
    open(path * "$name.json", "w") do f
        write(f, json_str)
    end 
    json_str
end 

function save_df_as_csv(name::String, date::String, df::DataFrame)
    path = processed_data_path() * date * "/"
    trymkdir(path)
    CSV.write(path * name, df)
end 


function save_object(object, name::String, path::String)
    if isa(object, DataFrame)
        @info "Saving results to $(name).csv"
        CSV.write(path * name * ".csv", object)
    else 
        @info "Saving results to $(name).json"
        save_json(object, name, path)
    end
end 

function update_value(dict::Dict, key::String, value)
    d = dict |> deepcopy
    d[key] = value 
    return d 
end 

function update_values(dict::Dict, key::String, values)
    map(collect(values)) do value 
        update_value(dict, key, value)
    end 
end 

function convert_arrow_to_datetime(df::DataFrame)::DataFrame
    for name in names(df)
        try 
            element = df[1, name]
            convert(Dates.DateTime, element)
            df[!, name] = map(to_datetime, df[!, name])
        catch 
            # element cannot be converted to datetime, so we skip it 
        end 
    end 
    df 
end 

function convert_datetime_to_string!(df::DataFrame)::DataFrame
    for name in names(df)
        if df[1, name] isa Dates.DateTime 
            df[!, name] = map(time_to_string, df[!, name])
        end 
    end 
    df 
end 

function convert_substring_to_string!(df::DataFrame)::DataFrame
    for name in names(df)
        if df[1, name] isa SubString 
            df[!, name] = map(String, df[!, name])
        end 
    end 
    df 
end 

function convert_categorical!(df::DataFrame)::DataFrame
    for name in names(df)
        if df[1, name] isa MLJ.CategoricalArrays.CategoricalValue{Int64, UInt32} 
            df[!, name] =  int(df[!, name], type=Int)
        end 
    end 
    df 
end 
# Select $size random elements from an array 
function select_random(arr, size::Int)
    if length(arr) < size 
        return arr
    else 
        return arr[randperm(length(arr))][1:size]
    end 
end 

function select_one_random(arr)
    select_random(arr, 1) |> first 
end 

function select_one_random(df::DataFrame)
    index::Int = sample(1:size(df, 1))
    return df[index, :]
end 

function select_random(df::DataFrame, n::Int)
    if size(df, 1) < n 
        return error("Not supporting resampling if df too small.") 
    else 
        permutation = randperm(size(df, 1))
        return df[permutation, :] |> (df -> first(df, n))
    end 
end 

function compress(file_path::String, file_name::String, new_file_name::String)
    current_dir = pwd()  
    cd(file_path)
    run(`zip -r $new_file_name $file_name`)
    cd(current_dir)
end 

function compress_folder(folder_path::String, folder_name::String, zip_file_name::String)
    current_dir = pwd()  
    cd(folder_path)
    run(`zip -r $zip_file_name $folder_name`)
    cd(current_dir)
end 

function decompress(file_path::String)
    run(`unzip $file_path`)
end 

function decompress(file_path::String, save_path::String)
    run(`unzip $file_path -d $save_path`)
end

function gunzip(file_path::String)
    run(`gunzip $file_path`)
end

function decompress_tgz(file_path::String; save_path=canad_data_path())
    run(`tar zxvf $file_path -C $(save_path)`)
end

function add_padding_to_image(image, max_length::Int)
    if size(image, 2) == max_length    
        return image 
    elseif size(image, 2) > max_length
        @warn "Cutting image. Image size = $(size(image)), max = $max_length"
        return image[:, 1:max_length]
    else 
        return cat(image, zeros(size(image, 1), max_length - size(image, 2)), dims = 2)
    end 
end 

function trysoftmax(prediction)
    if sum(prediction) ≈ 1 atol = 1e-4
        return prediction 
    else 
        return softmax(prediction)
    end 
end 

function save_object(obj, name="object", path=session_path(), id=rand_id())
    file_path = path * "$(name)_$id.jld"
    jldopen(file_path, "w") do file
        write(file, "$name", obj)
    end
    @info "saved $file_path"
    return file_path
end 

function df_to_disk(path, df::DataFrame)
    # Parquet.jl does not support DateTime or SubString yet. 
    df = df |>  convert_datetime_to_string! |>  convert_substring_to_string! |> convert_categorical!
    write_parquet(path, df)
end 

# We construct objects using "factories", therefore we don't know the id at initilization. We add it here after the fact. 
function add_ids!(objects)
    if !ismissing(objects[1].id) 
        return objects 
    end 
    
    i = 0 

    new_objects = map(objects) do object 
        @assert ismissing(object.id) 
        i += 1 
        @set object.id = i 
    end 

    @assert new_objects[1].id == 1 
    @assert new_objects[end].id == length(objects)
    return new_objects 
end

function get_most_likely_id(list, values)::Int 
    if maximum(values) ≈ 0 atol = 1e-4
        return 0
    end 
    item = list[argmax(values)]
    return item.id 
end 

function include_folder(folder)
    for file in readdir("src/" * folder)
        if occursin(".jl", file)
            include("$folder/$file")
        end 
    end 
end 

function run_experiment(funct)
    try 
        funct()
        send_notification!("Experiment completed")
    catch e
        send_notification!("Experiment failed")
        throw(e)
    end 
end 
    
function convert_dict_keys_to_string(dict::Dict)::Dict{String, Any}
    new_dict = Dict()
    for (key, value) in dict
        new_dict[string(key)] = value
    end 
    return new_dict
end

include("throttle.jl")
include("cplex_utils.jl")
include("aws_utils.jl")
include("slurm_utils.jl")