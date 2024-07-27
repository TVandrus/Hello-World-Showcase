# MyIsolationForest.jl 

module MyIsolationForest 

using ..MyCART
using DataFrames, CategoricalArrays, Random, Statistics, StatsBase, Base.Threads

"""
Unsupervised algorithm to identify anomalies/outliers by separating data at random values along random features
Unusual instances will be more easily/quickly separated, and terminate in leaf nodes at shallower depth
Run many times, return average depth that an instance terminates in a leaf 

Alternative: for each split, pick a random variable as the 'target', 
and optimize a split to minimize dispersion of that variable in each child node

"""

function rand_split(instance_id::AbstractVector, data, curr_depth, blacklist=[]; max_depth=20, leaf_threshold=1, optimal_split=false)
    @assert curr_depth < max_depth "attempted split beyond max_depth"
    @assert nrow(data) > leaf_threshold >= 1 "attempted split on isolated data"
    
    vars = setdiff(shuffle(propertynames(data)), blacklist)
    for v in vars
        if length(unique(data[!, v])) == 1
            # can't split, remove var to avoid re-checking
            push!(blacklist, v)
            # try next var 
        else 
            if isa(splitcol, CategoricalVector)
                splitcond = isequal
            else#if isa(splitcol, AbstractVector)
                splitcond = MyCART.isless_eq
            end

            # maybe loss = remaining dispersion of the splitvar?
            if optimal_split
                if isa(splitcol, CategoricalVector)
                    optimal_lossfn = MyCART.gini
                else
                    optimal_lossfn = MyCART.msdev
                end
                split_record = MyCART.split(data[!, v], data[!, v], optimal_lossfn, )
            else # random split
                rand_val = StatsBase.sample(unique(data[!, v]), 1) 
                split_record = (splitvar=v, splitcond=splitcond, splitval=rand_val, loss=0) 
                
            end
        end
    end
end

function grow_isolation_tree(tree::Dict{String, Node}, data::AbstractDataFrame, obs::Vector{Int}, selfID::String, max_tree_depth::Int, min_leaf_size::Int; 
        nsplitvars::Int=ncol(data), lossfn::Function, gatherfn::Function)::Dict{String, Node}
    # stopping case: if invalid to split, return a leaf to the tree
    if max_tree_depth < 1 || length(obs) <= min_leaf_size || length(unique(data[obs, :target])) == 1
        push!(tree, selfID => Node(selfID, obs, nothing, nothing, nothing, lossfn(data[obs, :target]), gatherfn(data[obs,:target])))
    else # otherwise return split node; grow a tree on each part of the split observations
        opt_split = find_split(data[obs,:], nsplitvars=nsplitvars, lossfn=lossfn)
        if opt_split.loss == Inf
            push!(tree, selfID => Node(selfID, obs, nothing, nothing, nothing, lossfn(data[obs, :target]), gatherfn(data[obs, :target])))
        else
            push!(tree, selfID => Node(selfID, obs, opt_split.splitvar, opt_split.splitcond, opt_split.splitval, lossfn(data[obs, :target]), nothing))
            left = opt_split.splitcond.(data[obs, opt_split.splitvar], opt_split.splitval)
            merge!(tree, 
                grow_tree(tree, data, obs[left], selfID*"L", max_tree_depth-1, min_leaf_size, nsplitvars=nsplitvars, lossfn=lossfn, gatherfn=gatherfn),
                grow_tree(tree, data, obs[.! left], selfID*"R", max_tree_depth-1, min_leaf_size, nsplitvars=nsplitvars, lossfn=lossfn, gatherfn=gatherfn))
        end
    end
    return tree
end
