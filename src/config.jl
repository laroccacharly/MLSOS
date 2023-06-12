cnsolver_config = Dict{String, Any}(
    "seed" => 0, 
    "cplex_time_limit" => parse(Int, get(ENV, "TIME_LIMIT", "3600")), 
    "test_instance_radius" => 1150,
    "test_instance_nhours" => 24 * 7, 
    "show_cplex_stdout" => true,
    "lpp_label_type" => RailcarLoadingPatternAssignment(),
    "callback_action_type" => UserCut(),
    "loading_pattern_type" => OriginalLoadingPatterns(), 
    "enable_hybrid_assignment" => false, # Only valid for LPP
    "load_solution_on_lp_nodes" => false, # Disabled by default for performance reasons.
    "alternative_constraint_format" => false, # Testing changing the constraint from == to > 
    "bnb_indexer" => FloorNodeCount(15),  # TemporalIndexing(0.5)
    "fixing_ratio" => 0.5, 
    "scoring_type" => HistoricalEntropyScore(), 
    "action_depth" => 8, 
    "nthreads" => 1,
)

function get_value(field::String)
    return cnsolver_config[field]
end 

function update_cnsolver_config!(field::String, value)
    cnsolver_config[field] = value 
    global cnsolver_config = cnsolver_config 
end 

function update_cnsolver_config!(dict::Dict)
    for (key, value) in dict
        update_cnsolver_config!(key, value)
    end
end 


processed_data_path() = "processed_data/" 
raw_data_path() = "raw_data/"
raw_files_to_download() = [
]
raw_path_url() = ""

stations_file_name() = ".parquet"
nlight_arcs_per_ground_node() = 10 
mainline_only() = true 
mainline_train_types() = ["A", "B", "C", "E", "G", "M", "Q", "S", "U", "X"]

dataset_min_time() = to_datetime("01/07/2017 00:00:00")
# Test instance 
test_instance_start_time() = dataset_min_time() + Day(3)
test_instance_source_path() = processed_data_path() 
test_instance_file_path() =  test_instance_source_path() * test_instance_file_name()
test_instance_file_name() =  "test_instance.jld"
test_instance_radius() = get_value("test_instance_radius") 
test_instance_nhours() = get_value("test_instance_nhours") 

neighbourhood_image_length() = 75
allowed_hp_range() = (7500, 12500)

const consist_building_time = Minute(15)
const consist_busting_time = Minute(15)

show_cplex_stdout() = get_value("show_cplex_stdout") 
cplex_time_limit() = get_value("cplex_time_limit")
get_nthreads() = get_value("nthreads")