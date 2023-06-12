miplib_zip_file_name = "collection.zip"
miplib_data_path() = joinpath(raw_data_path(), "miplib_data")

function decompress_miplib_folder!() 
    files = readdir(miplib_data_path())
    if length(files) == 0 
        println("Decompressing zip folder $miplib_zip_file_name ...")
        path = raw_data_path() 
        decompress(joinpath(path, miplib_zip_file_name), miplib_data_path())    
    end 
end 

function decompress_miplib_file(filename::String)
    @info "Decompressing zip file $filename ..."
    path = miplib_data_path()
    gunzip(joinpath(path, filename))
end

