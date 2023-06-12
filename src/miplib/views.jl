function Base.show(io::IO, i::MiplibInstanceType) 
    println(io, "MIPLIB instance $(name(i)) with $(length(get_objects(i))) sos constraints.") 
end 