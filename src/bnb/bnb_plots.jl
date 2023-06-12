# Plots consist_gap vs hp_group on a node
function plot_heatmap(node::BnBNode)
    if ismissing(node.solution_df)
        @warn "No solutions to plot"
        return 
    end 
    df = node.solution_df 
    matrix = zeros(Int8, maximum(df[!, :consist_gap]) + 1, maximum(df[!, :hp_group]))
    for row in eachrow(df)
        i = row.consist_gap + 1 
        j = row.hp_group
        matrix[i,j] += 1 
    end 
    heatmap(matrix) |> display
end 

# Plots consists gap for each candidate node in the tree 
# number of candidates, LP solutions 
# tracks metrics over time 
# number of LP solutions between two candidates 
# time between  each candidate node 
# total number of nodes (from cplex) at each candidate nodes 
function plot_tree(tree::BnBTree)
    @show tree.number_candidates
    nodes = candidate_nodes(tree)
    attributes_to_plot = [
        "cplex_node_count",
        "node_collected",
        "time",
        "best_sol"
    ]
    for attr in attributes_to_plot
        lineplot_nodes(nodes, attr)
    end 

end     

function lineplot_nodes(nodes, attribute::String)
    x = Number[i for i in 1:length(nodes)]
    y = Number[node.cplex_info[attribute] for node in nodes]
    lineplot(x, y, title = "$attribute for each node", 
    xlabel = "candidate_node" , ylabel = attribute) |> display  
end 

function Base.show(io::IO, tree::BnBTree) 
    println(io, "BnB Tree with $(length(tree.nodes)) nodes")
    println(io, to_df(tree))
end 

function Base.show(io::IO, node::BnBNode) 
    println(io, "BnB Node $(node.cb_context_id)")
    println(io, display(node.cplex_info)) 
    if !ismissing(node.solution_df)
        println(io, node.solution_df)
    end 
end 