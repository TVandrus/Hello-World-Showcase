# MyNeuralNet.jl
"""
Provides basic capability to construct and train a basic feed-forward network  
Supports classification and regression  
Arbitrary number of hidden layers of arbitrary size  
Options to provide activation, output, and error functions to replace defaults
"""
module MyNeuralNet

using CategoricalArrays, Statistics, Plots
import StatsBase.sample
export display, sigmoid, relu, reg_out, softmax, cross_entropy, mse, mae
export NNet, one_hot_encode, one_hot_decode, predict, learn_backprop, train_NNet, new_NNet

# https://machinelearningmastery.com/implement-backpropagation-algorithm-scratch-python/
# https://medium.com/@14prakash/back-propagation-is-very-simple-who-made-it-complicated-97b794c97e5c
# https://visualstudiomagazine.com/articles/2017/06/01/back-propagation.aspx
# https://mattmazur.com/2015/03/17/a-step-by-step-backpropagation-example/
# https://en.wikipedia.org/wiki/Backpropagation

struct NNet
    target_type::Symbol # :regression or :classification
    labels::Union{Vector, Nothing}
    design::Vector{T where T <: Integer}
    bias::Number
    act_fn::Function # relu by default
    out_fn::Function # identity or softmax
    loss_fn::Function # mse or cross_entropy
    weights::Dict{Int, Matrix{T where T <: Number}} # experiment w lower precision?
end

function Base.display(nn::NNet)
    println(typeof(nn))
    println(nn.target_type)
    println(nn.design)
    println(nn.act_fn)
    println(nn.out_fn)
    println(nn.loss_fn)
end

function relu(v::Vector; derivative::Bool=false)::Vector{T where T <: Number}
    u = copy(v)
    u[v .< 0] .= zero(typeof(v[1]))
    if derivative
        u[v .> 0] .= one(typeof(v[1]))
    end
    return u
end

function sigmoid(v::Vector; derivative::Bool=false)::Vector{T where T <: Number}
    if derivative
        s = 1 ./ (1 .+ exp.(.-v))
        return s .* (1 .- s)
    else
        return 1 ./ (1 .+ exp.(.-v))
    end
end

function reg_out(out; derivative::Bool=false)
    if derivative
        return 1
    else
        return out[1]
    end
end

function softmax(v::Vector; derivative::Bool=false)::Vector{T where T <: Number}
    u = copy(v)
    u = u .- maximum(u) # improve numerical stability for large terms
    # ie avoid exp(1000)
    if derivative
        return [(exp(u[i]) * sum(exp.(u[begin:end .!= i]))) / sum(exp.(u))^2 for i in 1:length(u)]
    else
        return (exp.(u) / sum(exp.(u)))
    end
end

function cross_entropy(y_hat::Vector, y::Vector; derivative::Bool=false)
    if derivative
        return [(-(y[i]*log(1/y_hat[i])) + ((1-y[i])*log(1/(1-y_hat[i])))) for i in 1:length(y)]
    else
        return -sum(y .* log.(y_hat))
    end
end

function cross_entropy(y_hat::Matrix, y::Matrix)
    return mean( [ -sum(y[i, :] .* log.(y_hat[i, :])) for i in size(y_hat, 1) ] )
end

function mse(y_hat, y; derivative::Bool=false)
    if derivative
        return [(y_hat .- y)]
    else
        return 0.5 * mean((y_hat .- y) .^ 2)
    end
end

function mae(y_hat, y; derivative::Bool=false)
    if derivative
        return (y_hat .- y) >= 0 ? 1 : -1
    else
        return mean(abs.(y_hat .- y))
    end
end

"""
Turn a k-level CategoricalVector with n-observations into n-by-k Matrix of ones/zeros  
Provides the array of labels used
"""
function one_hot_encode(v::CategoricalVector; labels::Vector=[])::Tuple{Vector, Matrix}
    if length(labels) > length(levels(v))
        lev = labels
    else
        lev = levels(v)
    end
    m = zeros(Integer, (length(v), length(lev)))
    for c in 1:length(lev)
        m[(lev[c] .== v), c] .= one(Integer)
    end
    return (lev, m)
end

"""
Turn an n-by-k Matrix of ones/zeroes into n-by-1 CategoricalVector using the provided labels
"""
function one_hot_decode(labels::Vector, m::Matrix)::CategoricalVector
    @assert length(labels) >= size(m, 2) "Not enough labels"
    v = [argmax(r) for r in eachrow(m)]
    return CategoricalVector(labels[v])
end

function predict(X::Matrix, model::NNet)::AbstractArray
    if model.target_type === :classification
        predictions = zeros(size(X, 1), length(model.labels))
    elseif model.target_type === :regression
        predictions = zeros(size(X, 1))
        @debug "regression 1"
    end
    
    for i in 1:size(X, 1)        
        layer = X[i, :]
        for j in 1:length(model.weights)
            layer = model.weights[j]' * layer 
            # activation for transfers prior to output
            if j < length(model.weights)
                layer = model.act_fn(layer .+ model.bias)
            end
        end
        # final activation
        if model.target_type === :classification
            predictions[i, :] = softmax(vec(layer))
        elseif model.target_type === :regression
            @debug "regression 2"
            predictions[i] = layer[1]

        end
    end
    return predictions
end

function learn_backprop(Y, X, model::NNet, learn_rate::Float64)::Tuple{NNet, Number}
    Y_hat = zeros(size(Y))
    loss = zeros(size(Y, 1))
    out_dim = size(Y, 2) == 1 ? 1 : 1:size(Y, 2)

    weights = model.weights
    up_weights = Dict{Int, Matrix}()
    n_weights = length(weights)
    activations = Dict{Int, Vector}()
    layers = Dict{Int, Vector}()
    
    for i in 1:size(X, 1)
        # calculate forward propagation
        layers[1] =  X[i, :]
        for j in 1:n_weights
            activations[j] = weights[j]' * layers[j]
            if j < n_weights
                layers[j+1] = model.act_fn(activations[j] .+ model.bias)
            end
        end
        # apply output transfer function
        Y_hat[i, out_dim] = model.out_fn(activations[n_weights])
        # calculate error
        loss[i] = model.loss_fn(Y_hat[i, out_dim], Y[i, out_dim])
        @debug display(Y_hat[i, out_dim])
        @debug display(Y[i, out_dim])
        # backpropagate errors and calculate gradients
        δ::Matrix{Number} = (model.loss_fn(Y_hat[i, out_dim], Y[i, out_dim], derivative=true) 
            .* model.out_fn(activations[n_weights], derivative=true))'
        #display(model.loss_fn(Y_hat[i, :], Y[i, :], derivative=true))
        #display(model.out_fn(Y_hat[i, :], derivative=true))
        for k in n_weights:-1:1
            # update weights
            #display(weights[k])
            #display(δ)
            #display(layers[k])
            up_weights[k] = weights[k] .- (learn_rate .* (layers[k] * δ))
            #println("here three")

            if k > 1
                #display(δ)
                #display(up_weights[k]')
                #display(model.act_fn(activations[k-1], derivative=true)')
                δ = δ * weights[k]' .* model.act_fn(activations[k-1], derivative=true)'
            end
        end
        #println("here 4")
        weights = up_weights
    end

    return (NNet(model.target_type, model.labels, model.design, 
                model.bias, model.act_fn, model.out_fn, model.loss_fn,
                weights),
            mean(loss))
end

#function learn_evolution(Y, X, model, learn_rate)
    # given model and training data

    # generate mutated models
    
    # predict data, then calculate errors for each model

    # select top-performing models

#end

"""
learn_mode:
    :backprop - gradient descent

sample types:  
    :bootstrap - random sample with replacement  
    :subset - random sample without replacement  
    :sequential - contiguous rows in order  
"""
function train_NNet(trainY::AbstractVector, trainX::Matrix, model::NNet, 
                    learn_mode::Symbol=:backprop, learn_rate::Number=0.01; 
                    epochs::Integer=100, sample_type::Symbol=:bootstrap, sample_size::Integer=size(trainX, 1), 
                    testY::Union{Nothing, AbstractVector}=nothing, testX::Union{Nothing, Matrix}=nothing)
    @assert size(trainY, 1) == size(trainX, 1) "Number of observations in trainX and trainY must match"
    test_data = !(isnothing(testY) | isnothing(testX))
    if test_data
        @assert size(testY, 1) == size(testX, 1) "Number of observations in testX and testY must match"
    end

    if trainY isa CategoricalVector
        trainY = one_hot_encode(trainY, labels=model.labels)[2]
        if test_data
            testY = one_hot_encode(testY, labels=model.labels)[2]
        end
    end
    
    if sample_type === :bootstrap
        samp_fn = x -> rand(1:size(trainY, 1), sample_size)
    elseif sample_type === :subset
        @assert sample_size <= size(trainY) "cannot sample that size without replacement"
        samp_fn = x -> sample(1:size(trainY), sample_size)
    elseif sample_type === :sequential
        samp_fn = x -> [ind % size(trainY, 1) + 1 for ind in (0:sample_size-1) .+ (sample_size * (x-1))]
    else
        @error "Sampling type not implemented"
    end

    if learn_mode === :evolution
        train_fn = (Y, X, NN, lr) -> learn_evolution(Y, X, NN, lr)
    elseif learn_mode === :backprop
        train_fn = (Y, X, NN, lr) -> learn_backprop(Y, X, NN, lr)
    else
        @error "Learning mode not implemented"
    end

    train_loss = zeros(epochs)
    test_loss = zeros(epochs)

    for i in 1:epochs
        epSamp = samp_fn(i)
        epY = trainY[epSamp, :]
        epX = trainX[epSamp, :]
        model, train_loss[i] = train_fn(epY, epX, model, learn_rate)
        if test_data
            loss_acc = 0
            predY = predict(testX, model)
            for j in 1:size(predY, 1)
                loss_acc += model.loss_fn(predY[j,:], testY[j,:])
            end
            test_loss[i] = loss_acc / size(predY, 1)
        end
    end

    println(round.([train_loss test_loss], digits=4))
    plt = plot(1:epochs, train_loss, labels="train")
    plt = plot!(plt, 1:epochs, test_loss, labels="test")
    
    return model, plt
end

"""
Initializes a NNet with random weights 
    with parameters based on the data (which can be a small sample, not a full training set)  
Note: for categorical data, all possible targets/levels must appear in Y 
    in order for the NNet to have an output for each
"""
function new_NNet(Y::AbstractVector, X::Matrix, hidden_design::Vector{I} where (I <: Integer);
                act_fn=relu, out_fn=missing, loss_fn=missing)
    # initialise default behaviours as needed
    if Y isa CategoricalVector
        output_mode = :classification
        dout_fn = softmax
        dloss_fn = cross_entropy
        labels = levels(Y) # all levels must appear in initial Y
        output_design = length(labels)
    elseif Y isa Vector{N} where (N <: Number)
        output_mode = :regression
        dout_fn = reg_out
        dloss_fn = mse
        labels = nothing
        output_design = 1
    else
        @error "Unknown data type for Y"
    end

    design = cat(size(X, 2), 
                hidden_design, 
                output_design,
                dims=1)
    weights = Dict{Int, Matrix{Number}}()
    for w in 1:(length(design) - 1)
        push!(weights, w=>(1 .- 2 .* rand(design[w], design[w+1])))
    end

    return NNet(output_mode, labels, design, 1, act_fn, coalesce(out_fn, dout_fn), coalesce(loss_fn, dloss_fn), weights)
end

end # module
