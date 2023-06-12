struct CannotSaveSolutionError
    message::String
end 

include("mip/consists_helpers.jl")
include("mip/callbacks.jl")
include("mip/build_model.jl")

