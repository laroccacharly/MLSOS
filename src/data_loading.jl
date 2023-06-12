
function download_raw_data!() 
    for file in raw_files_to_download()
        if !isfile(raw_data_path() * file)
            @info "Could not find raw file $file. Downloading it."
            run(`wget --directory-prefix=$(raw_data_path()) $(raw_path_url())$file`)
        end 
    end 
end 
raw_station_locations() = CSV.read(raw_data_path() * ".csv", DataFrame)
raw_trains_operated() = CSV.read(raw_data_path() * ".csv", DataFrame)
twl_consists() = Feather.read(raw_data_path() * ".feather")


preprocess(p::FeatherBackend, df::DataFrame) = df 
function preprocess(p::ParquetBackend, df::DataFrame)::DataFrame 
    df |>  convert_datetime_to_string! |>  convert_substring_to_string! |> convert_categorical!
end 

extension(p::FeatherBackend) = ".feather"
extension(p::ParquetBackend) = ".parquet"

write_to_disk(p::FeatherBackend, path::String, df::DataFrame) = Feather.write(path, df)
write_to_disk(p::ParquetBackend, path::String, df::DataFrame) = write_parquet(path, df)

read_from_disk(p::FeatherBackend, path::String) = Feather.read(path)
read_from_disk(p::ParquetBackend, path::String) = DataFrame(read_parquet(path))

function save_df(protocol::FileStorageProtocol, path::String, filename::String, df::DataFrame)
    df = preprocess(protocol, df)
    full_path = path * filename * extension(protocol)
    write_to_disk(protocol, full_path, df)
end 

function load_dataframes(protocol::FileStorageProtocol, path::String)::Dict{String, DataFrame}
    filenames = readdir(path) |> (e -> filter(r -> occursin(extension(protocol), r), e))
    dataframes = Dict{String, DataFrame}()
    for filename in filenames 
        dataframes[split(filename, ".")[1]] = read_from_disk(protocol, path * filename)
    end 
    return dataframes 
end 

