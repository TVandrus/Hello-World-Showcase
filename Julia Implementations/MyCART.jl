# MyCART.jl

module MyCART

using DataFrames, Statistics, CategoricalArrays
using StatsBase:sample
export Node, Tree, display, mse, gini, mode, isless_eq, display, fit_tree, predict

# Classification And Regression Trees
struct Node
    selfID::String
    observations::Vector{Int}
    splitvar::Union{Symbol, Nothing}
    splitcond::Union{Function, Nothing}
    splitval::Any
    loss::Union{Float64, Nothing}
    leafval::Any
end

struct Tree
    tree::Dict{String, Node}
    # store full data points when single tree,
    #   only indices when part of a Forest
    data::Union{AbstractDataFrame, Vector{Int}}
end

function Base.display(n::Node)
    #println(typeof(n))
    print(n.selfID)
    if isnothing(n.leafval)
        println("  Split Node")
        println(n.splitvar," ",n.splitcond," ",n.splitval)
        println("Loss: ", round(n.loss, digits=4))
    else
        println("  Leaf Node")
        println("Value: ", n.leafval)
        println("Loss: ", round(n.loss, digits=4))
    end
    println(length(n.observations)," observations\n")
end

function Base.display(t::Tree)
    println(typeof(t))
    for b in keys(sort(t.tree))
        display(t.tree[b])
    end
end

function msdev(v::Vector)::Float64
    return length(v)==0 ? 0 : mean((v .- mean(v)) .^ 2)
end

function gini(v::CategoricalVector)::Float64
    if length(v) == 0
        return 0
    else
        s = 1
        for u in unique(v)
            s -= (count(t->t==u, v) / length(v))^2
        end
        return s
    end
end

function isless_eq(a,b)
    return a <= b
end

function mode(v::AbstractArray)
    sv = sort(v)
    result = sv[1]
    c = 0
    for u in unique(v)
        cu = count(x->isequal(u, x), sv)
        if cu > c
            result = u
            c = cu
        end
    end
    return result
end

function split(target::AbstractVector, splitcol::AbstractVector, lossfn::Function; splitcond::Function=isless_eq)
    # determine optimal split point for the variable and associated loss
    # for any target, numeric variable
    splitdata = DataFrame(target=target, data=splitcol)
    @assert nrow(splitdata) > 1 "insufficient data passed to split"
    sort!(splitdata, :data)

    if isa(splitcol, CategoricalVector)
        splitcond = isequal
    elseif isa(splitcol, Vector)
        splitcond = isless_eq
    end
        
    best = (splitval=splitcol[1], loss=Inf)
    if length(unique(splitdata.data)) == 1
        # don't split
    else
        for val in unique(splitdata.data)
            left = splitcond.(splitdata.data, val) # right = .! left
            vloss = (lossfn(splitdata.target[left])*sum(left) + lossfn(splitdata.target[.! left])*sum(.! left)) / length(left)
            if vloss < best.loss
                best = (splitval=val, loss=vloss)
            end
        end
    end
    return merge((splitcond=splitcond,), best)
end

function find_split(data::AbstractDataFrame; nsplitvars::Int=ncol(data), lossfn::Function)
    # determine optimal splitvar by minimizing loss
    best = (splitvar=:None, splitcond=isequal, splitval=nothing, loss=Inf)
    for col in sample(propertynames(data)[2:end], nsplitvars, replace=false)
        #test_split = merge((splitvar=col,), split(data.target, data[col], lossfn)) # reduces allocations
        test_split = merge((splitvar=col,), split(data[!,:target], data[!,col], lossfn))
        if test_split.loss < best.loss
            best = test_split
        end
    end

    return best #split details
end

function grow_tree(tree::Dict{String, Node}, data::AbstractDataFrame, obs::Vector{Int}, selfID::String, max_tree_depth::Int, min_leaf_size::Int; 
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

"""
Train and return a single decision Tree object \n
**Required args** \n 
target - labels for observations, supports numeric Vector for regression, or CategoricalVector for classification\n
data - table of observations \n

**Optional Keyword args** \n
max_tree_depth - \n
min_leaf_size - minimum # of observations to allow further splits\n
nsplitvars - number of variables to consider when looking for an optimal split\n
lossfn - allows custom loss function to be passed \n 
vars - allows an arbitrary subset of variables from data to be specified \n
"""
function fit_tree(target::AbstractVector, data::AbstractDataFrame; max_tree_depth::Int, min_leaf_size::Int=1, 
                  nsplitvars::Int=ncol(data), lossfn::Union{Nothing, Function}=nothing, vars::Union{Nothing, Vector}=nothing)
    @assert length(target) == nrow(data) "data must have same number of observations as target"
    @assert 1 <= max_tree_depth < 256 "please try reasonable max tree depth"
    @assert 1 <= min_leaf_size <= length(target) "please try reasonable min leaf size"
    @assert 1 <= nsplitvars <= ncol(data) "please try a reasonable number of splitting variables"
    
    tree = Dict{String, Node}(); #sizehint!(tree, min(nrow(data) / min_leaf_size, 2^max_tree_depth))
    if !isnothing(vars)
        data = data[vars]
    end
    data = [target data]
    rename!(data, ["target"; names(data)[2:end]])
    if isa(target, CategoricalVector)
        gatherfn = mode
        if isnothing(lossfn)
            lossfn = gini
        end
    elseif isa(target, Vector)
        gatherfn = mean
        if isnothing(lossfn)
            lossfn = msdev
        end
    else
        error("target invalid data type")
    end
    merge!(tree, grow_tree(tree, data, Vector(1:nrow(data)), "root", max_tree_depth, min_leaf_size, 
                            nsplitvars=nsplitvars, lossfn=lossfn, gatherfn=gatherfn))
    return Tree(tree, data)
end

function predict(X::DataFrameRow, model::Tree)
    nd = "root"
    while isnothing(model.tree[nd].leafval)
        if model.tree[nd].splitcond(X[model.tree[nd].splitvar], model.tree[nd].splitval)
            nd = nd*"L"
        else
            nd = nd*"R"
        end
    end
    return model.tree[nd].leafval
end

function predict(X::AbstractDataFrame, model::Tree)
    Yhat = []
    for row::DataFrameRow in eachrow(X)
        push!(Yhat, predict(row, model))
    end
    return Yhat    
end

end # module