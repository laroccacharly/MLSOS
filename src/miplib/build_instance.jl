struct MiplibInstance <: MiplibInstanceType
    scenario::MiplibScenarioType
    model::JuMP.Model
    sos_constraints::Vector{SOSConstraintType}
end
get_objects(instance::MiplibInstanceType) = instance.sos_constraints
get_objects(instance::MiplibInstanceType, label_type::LabelType) = get_objects(instance)
get_scenario(instance::MiplibInstanceType) = instance.scenario
problem_name(::MiplibInstanceType) = "miplib"
name(instance::MiplibInstanceType) = name(instance.scenario)
struct InvalidMiplibInstance <: MiplibInstanceType
    scenario::MiplibScenarioType
    error
end
is_valid(instance::MiplibInstance) = true
is_valid(instance::InvalidMiplibInstance) = false
jump_model_is_built(::MiplibInstance) = true
jump_model_is_built(::ProblemInstance) = false
get_jump_model(instance::MiplibInstance) = instance.model
function build_instance!(scenario::MiplibScenarioType)::MiplibInstanceType
    try 
        model = load_miplib_jump_model(scenario)
        sos_constraints = build_sos_constraints(model)
        return MiplibInstance(scenario, model, sos_constraints)
    catch ex
        return InvalidMiplibInstance(scenario, ex)
    end 
end 

function load_miplib_jump_model(scenario::MiplibScenarioType)::JuMP.Model
    path = miplib_data_path()
    # .mps files are compress with gzip. 
    # We need to decompress them before reading them.
    if isfile(joinpath(miplib_data_path(), zip_filename(scenario))) 
        decompress_miplib_file(zip_filename(scenario))
    end

    if isfile(joinpath(miplib_data_path(), mps_filename(scenario))) 
        @info "Loading model $(mps_filename(scenario)) ..."
        model = JuMP.read_from_file(joinpath(path, mps_filename(scenario))) 
    else
        error("File $(mps_filename(scenario)) not found.")
    end

    return model
end 
