module MLSOS 

using CPLEX, CSV, Memoize
using DataFrames, DataFramesMeta, Distances, Interpolations, OnlineStatsBase, OnlineStats
using Feather, Arrow, Parquet, JSON, Logging, LinearAlgebra, Combinatorics, Distributions
using Parameters, Polynomials, ProgressMeter, Random, Retry, InformationMeasures, JLD, JuMP
using Setfield, Statistics, StatsBase, Suppressor, UUIDs, UnicodePlots, Crayons, Dates, MetaGraphs

import Query: @orderby, @filter, @groupby, key 
import CategoricalArrays: categorical

using MLJ, DecisionTree
import MLJDecisionTreeInterface, MLJXGBoostInterface

import JuMP: Model 

files = [
    "utils.jl",
    "types.jl", 
    "config.jl",
    "paths.jl", 
    "data_loading.jl", 
    "instances.jl",
    "selection_strategy.jl",
    "bnbtree.jl", 
    "schedulers.jl", 
    "scores.jl",
    "labelling.jl", 
    "miplib.jl",
    "callback_state.jl",
    "solver_results.jl", 
    "database.jl", 
    "dataset.jl",
    "solver_params.jl",
    "algorithms.jl",
    "mip.jl",
    "policies.jl", 
    "learners.jl",
    "metrics.jl",
]

show_time_to_include = false  
for file in files 
    time_to_include = @elapsed include(file)
    if show_time_to_include
        @info "It took $time_to_include seconds to include file $file" 
    end 
end 

function __init__() 
    make_paths!() 
    @info "MLSOS is ready!"
end 

end 


