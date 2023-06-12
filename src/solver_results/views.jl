function Base.show(io::IO, results::SolverResultsType) 
    println(io, "Solver results for $(get_instance(results))")
    # println(io, results.tree)
    println(io, display(metrics_dict(results)))
    # println(io, "Total time to collect data: ", total_time_to_collect_data(results))
    # show_entropy_distribution(results)
end 

