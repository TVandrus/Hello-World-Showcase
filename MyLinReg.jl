# MyLinReg.jl

module MyLinReg

using DataFrames, LinearAlgebra
export MLR, display, fit_mlr, predict

# Multiple Linear Regression
struct MLR
    coef::Vector{Number}
    Yhat::Vector{Number}
    Y::Vector{Number}
    X::Matrix{Number}
    condition::Float16
end

function Base.display(m::MLR)
    println(typeof(m))
    println(round.(m.coef', digits=4))
end

function fit_mlr(Y::Vector, X::Matrix; add_int::Bool=false)::MLR

    if size(Y, 1) != size(X, 1)
        error("X and Y must have same number of observations")
        return nothing
    elseif size(X, 1) < size(X, 2)
        error("p > n, try regularized regression")
        return nothing
    end
    
    if add_int
        X = hcat(X, ones(Number, size(X,1)))
    end

    # https://en.wikipedia.org/wiki/Condition_number
    evals = eigvals(Matrix{Number}(X' * X))
    condition = sqrt(evals[end]) / evals[1]
    if condition > 30
        @warn "Matrix condition index > 30, indicates likely multicollinearity problem.\n
                Inversion will be attempted regardless."
    end
    
    # solve normal equations
    beta = inv(Matrix{Number}(X' * X)) * X' * Y
    Yhat = X * beta

    return MLR(beta, Yhat, Y, X, condition)
end

function predict(X::Matrix, model::MLR; add_int::Bool=false)
    if add_int
        X = hcat(X, ones(Number, size(X, 1)))
    end
    return X * model.coef
end

end # module