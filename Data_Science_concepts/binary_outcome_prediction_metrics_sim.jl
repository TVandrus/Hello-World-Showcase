#=
    evaluating quality of probabilistic predictions of binary outcomes 
    
    Modified Brier score for evaluating prediction accuracy for binary outcomes
    https://www.ncbi.nlm.nih.gov/pmc/articles/PMC9691523/
    Yang, W., Jiang, J., Schnellinger, E. M., Kimmel, S. E., & Guo, W. (2022). Modified Brier score for evaluating prediction accuracy for binary outcomes. Statistical methods in medical research, 31(12), 2287–2296. https://doi.org/10.1177/09622802221122391

    simulating predictions of various quality on data from different underlying processes 
    to determine interpretation and sensitivity of various scoring metrics
=#


using Statistics, Plots

base_p_event = 0.75;
n_sample = 50;
outcomes = rand(Float32, n_sample) .< base_p_event;
mean(outcomes)

# constant estimate of the mean, from an independent sample from the same process
sample_mean = mean(rand(Float32, 200) .< base_p_event)
pred_base = fill(sample_mean, n_sample);

# absolutely random 
pred_rand = rand(Float32, n_sample);

# always follows the outcome, but consistently reduced to represent imprefect confidence
doubt = 0.15;
pred_bias = abs.(outcomes .- doubt);


function scores(y_pred, y_truth) 
    results = []
    push!(results, "mean error: \t $(round(mean(y_pred .- y_truth); digits=3))")
    push!(results, "mean abs error: \t $(round(mean(abs.(y_pred .- y_truth)); digits=3))")
    push!(results, "root mean squared error: \t $(round(sqrt(mean((y_pred .- y_truth) .^ 2)); digits=3))")
    return results
end


@info join(scores(pred_base, outcomes), "\n") 
@info join(scores(pred_bias, outcomes), "\n") 
@info join(scores(pred_rand, outcomes), "\n") 



# simulate the predictions of multiple trials, across a range of processes
using Statistics, Plots

n_sample = 5000;

probs, scores = [], []
for p in range(0.02, 0.98; step=0.03)
    for trial in 1:7
        y_truth = rand(Float32, n_sample) .< p
        
        sample_mean = mean(rand(Float32, 200) .< p)
        #y_pred = fill(sample_mean, n_sample)
        doubt = 0.09
        y_pred = abs.(y_truth .- doubt)
        
        # classic root-mean-squared errors
        # err_pred = round(sqrt(mean((y_pred .- y_truth) .^ 2)); digits=3)
        
        # mean square error for the probability of binary outcome (MSEP) 
        # correct for natural variance of the process 
        # for more consistent interpretation/comparison between different applications
        pred_msep = round(
            sqrt(max(0, mean((y_pred .- y_truth) .^ 2)  
            - max(0.0001, (mean(y_truth) * (1 - mean(y_truth))))
            )) / mean(y_truth)
            ; digits=3
        )
        push!(scores, pred_msep)

        push!(probs, p)
    end
end 



# as variance of the underlying proess goes down (farther from p=0.5), the RMSE of a constant prediction goes down, appearing to be a smart prediction 

plt = Plots.plot(probs, scores, 
    xlabel="underlying prob", 
    ylabel="error measure", 
    seriestype=:scatter
)


