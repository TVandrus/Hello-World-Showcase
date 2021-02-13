# MyRandomForest.jl

module MyRandomForest

using ..MyCART
using DataFrames, Statistics, Base.Threads
export Forest, display, fit_forest, predict

struct Forest
    forest::Array{Tree, 1}
    # each tree has 
    data::AbstractDataFrame
    combinefn::Function
end

function Base.display(f::Forest)
    println(typeof(f))
    println("# of trees: ", length(f.forest),"\n")
    display(f.forest[1])
end

"""
Train and return a random forest object  
Required args  
target - labels for observations, supports numeric Vector for regression, or CategoricalVector for classification  
data - table of observations  

Optional Keyword args  
max_tree_depth -  
min_leaf_size - minimum # of observations to allow further splits  
ntrees - number of learners (trees) in bagged model  
nsplitvars - number of variables to consider when looking for an optimal split  
nsample - number of rows sampled from data, defaults to nrow(data)  
sample_replace - resample from data with replacement when true  
lossfn - allows custom loss function to be passed, defaults to mse() for regression, gini() for classification  
vars - allows an arbitrary subset of variables from data to be specified  
"""
function fit_forest(target::AbstractVector, data::AbstractDataFrame;
                    max_tree_depth::Int=log2(nrow(data)), min_leaf_size::Int=1, ntrees::Int=100, 
                    nsplitvars::Int=ceil(Int, sqrt(ncol(data))), nsample::Int=length(target), sample_replace=true, 
                    lossfn::Union{Nothing, Function}=nothing, vars::Union{Nothing, Vector}=nothing)::Forest
    @assert length(target) == nrow(data) "data must have same number of observations as target"
    @assert 1 <= max_tree_depth < 256 "please try reasonable max tree depth"
    @assert 1 <= min_leaf_size <= length(target) "please try reasonable min leaf size"
    @assert 1 <= nsplitvars <= ncol(data) "please try a reasonable number of splitting variables"

    forest = Array{Tree}(undef, ntrees)
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
            lossfn = mse
        end
    else
        error("target invalid data type")
    end
    
    for n in 1:ntrees
        boot = sample(1:length(target), nsample, replace=sample_replace)
        sort!(boot)
        forest[n] = Tree(grow_tree(Dict{String, Node}(), data, boot, "root", max_tree_depth, min_leaf_size, 
                                    nsplitvars=nsplitvars, lossfn=lossfn, gatherfn=gatherfn),
                         boot)
    end
    return Forest(forest, data, gatherfn)
end

function predict(X::DataFrameRow, model::Forest)
    ntrees = length(model.forest)
    Yhat = [predict(X, tree) for tree in model.forest]
    
    if model.combinefn == mode
        desc = "Proportion"
        info = count(x -> x==mode(Yhat), Yhat)
    elseif model.combinefn == mean
        desc = "Std Dev"
        info = std(Yhat)
    else
        desc = "No metric"
        info = nothing
    end
    return (estimate=model.combinefn(Yhat),
            estimates=Yhat,
            metric=desc,
            value=info)
end

function predict(X::AbstractDataFrame, model::Forest)
    ntrees = length(model.forest)
    Yhat = []; sizehint!(Yhat, ntrees)
    for row::DataFrameRow in eachrow(X)
        push!(Yhat, [predict(row, tree) for tree::Tree in model.forest])
    end
    estimate = model.combinefn.(Yhat)
    
    return (estimate=estimate,
            estimates=Yhat)
end

end # module