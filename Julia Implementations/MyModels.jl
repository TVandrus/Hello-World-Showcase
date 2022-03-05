# MyModels.jl

module MyModels

include("MyLinReg.jl") # export MLR, display, fit_mlr, predict
using .MyLinReg
include("MyCART.jl") # export Node, Tree, display, mse, gini, mode, isless_eq, display, fit_tree, predict
using .MyCART
include("MyRandomForest.jl") # export Forest, display, fit_forest, predict
using .MyRandomForest
include("MyRFClustering.jl") # export default_clust_RF, synth_data, clust_rf, prox_rf
using .MyRFClustering

include("MyNeuralNet.jl")
using .MyNeuralNet

end # module MyModels