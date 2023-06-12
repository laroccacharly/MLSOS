# Simulate array job from slurm locally 
task_ids = 1:3
for task_id in task_ids
    ENV["TASK_ID"] = string(task_id)
    include("main.jl")
end
ENV["TASK_ID"] = ""
