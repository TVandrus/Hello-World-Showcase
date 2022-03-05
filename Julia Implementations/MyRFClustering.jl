# RFCLustering.jl
#=
re-framing unsupervised learning/clustering as a supervised problem
allowing application of tree/forest-based models
=#

module MyRFClustering

using ..MyRandomForest
using DataFrames
export default_clust_RF, synth_data, clust_rf, prox_rf

"""
Override default parameters for clustering random forest\n
Same format to use for passing params to clust_rf\n\n
min_leaf_size - recommend greater than default of 1\n
sample_replace - use all samples in every tree 
"""
const default_clust_RF = (min_leaf_size=2,
                          sample_replace=false)

"""
Generate synthetic observations
based on sampling each variable in the dataset independently
"""
function synth_data(data::AbstractDataFrame, n::Int=nrow(data))::Tuple{AbstractVector, AbstractDataFrame}
    target = CategoricalArray([repeat(["real"], nrow(data)); repeat(["synth"], n)])
    sdata = DataFrame([rand(c, n) for c in eachcol(data)])
    rename!(sdata, names(data))
    return (target, DataFrame([data; sdata]))
end

"""
Convenience function to apply supervised RF classifier that separates original data points 
from synthesized data, clustering the real points in the process  
Uses MyModels.fit_forest() for Random Forest fitting  
default_clust_RF overrides some default parameters for the call to fit_forest(), 
but any/all can be overridden by the user using params
"""
function clust_rf(data::AbstractDataFrame, n_synth::Int=nrow(data); params::NamedTuple=())::Forest
    aug_target, aug_data = synth_data(data, n_synth)
    cust_params = merge(default_clust_RF, params)
    return MyModels.fit_forest(aug_target, aug_data; cust_params...)
end

"""
Given a clustering random forest object, 
calculate pairwise proximities for real data points  
"""
function prox_rf(f::Forest)::Matrix{Number}
    n_real = count(r -> r.target=="real", eachrow(f.data))
    n_trees = length(f.forest)
    leaves::Vector{Node} = []; sizehint!(leaves, n_trees * length(f.forest[1].tree) ÷ 2)

    for t::Tree in f.forest
        for n::Node in values(t.tree)
            if !isnothing(n.leafval)
                push!(leaves, n)
            end
        end
    end
    prox_inc::Float64 = 1 / n_trees # assumes every observation in every tree
    prox_mat = zeros(Float64, (n_real, n_real))
    for l::Node in leaves
        for i::Int in l.observations
            if i <= n_real
                for j::Int in l.observations
                    #if j >= i # generates upper triangular matrix
                        if j <= n_real
                            prox_mat[i,j] += prox_inc
                        else
                            break # short circuit, assumes observations are sorted
                        end
                    #end
                end
            end
        end
    end
    return prox_mat
end

end # module