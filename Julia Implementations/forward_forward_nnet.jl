#=
playing w the idea of Geoffrey Hinton's forward-forward neural net training algorithm concept, 
not as the most performant, but a much less computationally-expensive training algorithm

https://bdtechtalks.com/2022/12/19/forward-forward-algorithm-geoffrey-hinton/

https://www.cs.toronto.edu/~hinton/FFA13.pdf 
"The Forward-Forward algorithm is a greedy multi-layer learning procedure inspired by Boltzmann
machines (Hinton and Sejnowski, 1986) and Noise Contrastive Estimation (Gutmann and Hyvärinen,
2010). The idea is to replace the forward and backward passes of backpropagation by two forward
passes that operate in exactly the same way as each other, but on different data and with opposite
objectives. The positive pass operates on real data and adjusts the weights to increase the goodness in
every hidden layer. The negative pass operates on "negative data" and adjusts the weights to decrease
the goodness in every hidden layer."


paraphrase: 
predicting a binary outcome (1 or 0) as a probability

for each labelled data point 
    apply the weights between the input layer and hidden layer to generate the vector of activations
    take an objective function of the activation vector for the actual label
    take an objective function of the activation vector for the flipped (non-actual) label (can be symmetric ie -ve of the actual activation)
    update the weights according to the gradient of the (actual obj less flipped obj)
        such that an actual observation of 1 will lead to a high actual objective, and a similarly low flipped objective
        an actual observation of 0 should lead to a low actual objective, and a high flipped objective
        if a weight contributes +ve for 1, but also equally +ve for 0, then the difference is nothing, and the weight will be updated towards nothing, because it should be ignored/adds no value
            w * 0.99
        if a weight contributes high contrast/discriminatory value, then it will be amplified 
            w * 1.01
        if a weight contributes reversed contrast/discriminatory value, then it will be negated
            w * -1.01 
    output the activations
        if the next layer is another hidden layer
            normalize/constrain the magnitude of the activations (sigmoid?) so that the strength of each activation is not providing clues
        if the next layer is output 
            apply output transformation 
=#

#include("MyNeuralNet.jl")
#using .MyNeuralNet # re-use standard feed-forward architecture
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

sse = y -> sum(y .^ 2)

function learn_forward_forward(Y, X, model::NNet, learn_rate::Float64)::Tuple{NNet, Number}
"""


"""

# 


end