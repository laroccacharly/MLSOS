file_names = [
    "geo.jl",
    "jump_model_type.jl",
    "station_type.jl",
    "train_type.jl",
    "problem_instance_type.jl",
    "instance_type.jl",
    "formulation_type.jl",
    "lpp_type.jl", 
    "loading_patterns_type.jl",
    "problem_scenario_type.jl",
    "file_storage_type.jl",
    "locomotive_type.jl",
    "consist_type.jl",
    "selection_strategy_type.jl",
    "statistics_type.jl",
    "bnb_type.jl",
    "scheduler_type.jl",
    "label_type.jl",
    "lazy_constraint_type.jl",
    "scores_type.jl",
    "policy_type.jl",
    "action_type.jl",
    "dataset_type.jl",
    "learner_type.jl",
    "net_type.jl",
    "fcn_type.jl", 
    "miplib_type.jl",
    "callback_state_type.jl",
    "mip_algorithm_type.jl",
    "database_type.jl",
    "solver_params_type.jl",
    "solver_results_type.jl",
    "metric_type.jl",
]

for file in file_names
    include("types/$file")
end 