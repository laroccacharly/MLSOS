experiment_path() = processed_data_path() * "experiments/$(get(ENV, "EXPERIMENT_NAME", "default"))/"
init_time = Dates.now() 
session_path()::String = experiment_path() * "session_$(init_time)/"
db_path()::String = processed_data_path() * "db/"
results_base_path() = db_path() * "results/"
canad_data_path() = raw_data_path() * "canad/"

paths_to_make() = [
    db_path(),
    experiment_path(),
    results_base_path(),
]

function make_paths!()
    for path in paths_to_make() 
        trymkdir(path)
    end 
end 