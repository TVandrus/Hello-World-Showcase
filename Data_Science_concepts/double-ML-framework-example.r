require(datasets)

# collect data
head(Seatbelts)
dim(Seatbelts)
Y <- Seatbelts[,2]
T <- Seatbelts[,8]
X <- Seatbelts[,c(1,5,6,7)]

plot(Y ~ T)
naive_ML_model <- lm(Y ~ T + X[,])
naive_ML_model$coef['T']

effects = c()
for (i in 1:1000){
    # split into mutually-exclusive auxilliary and estimation subsets
    aux_1 <- sample(1:192, 96, replace=FALSE)

    # use preferred ML to model Y ~ T,X and T ~ X using auxilliary set
    # regularized models allowed and encouraged
    m_out_1 <- lm(Y[aux_1] ~ X[aux_1,]) 
    m_treat_1 <- lm(T[aux_1] ~ X[aux_1,]) 

    # use model to predict on estimation set, collect errors/residuals for predicted Y, T
    out_est_1 <- predict(m_out_1, data.frame(T[-aux_1], X[-aux_1,])) 
    out_err_1 <- Y[-aux_1] - out_est_1

    treat_est_1 <- predict(m_treat_1, data.frame(X[-aux_1,])) 
    treat_err_1 <- T[-aux_1] - treat_est_1

    # linearly regress Outcome residuals on Treatment residuals, estimate slope as treatment effect
    #plot(treat_err_1, out_err_1)
    effect_est_1 <- lm(out_err_1 ~ treat_err_1)
    effect_est_1$coef[2]

    # repeat procedure on reversed data sets

    aux_2 = c(1:192)[-aux_1]

    m_out_2 <- lm(Y[aux_2] ~ T[aux_2] + X[aux_2,]) 
    m_treat_2 <- lm(T[aux_2] ~ X[aux_2,]) 
    out_est_2 <- predict(m_out_2, data.frame(T[-aux_2], X[-aux_2,])) 
    out_err_2 <- Y[-aux_2] - out_est_2
    treat_est_2 <- predict(m_treat_2, data.frame(X[-aux_2,])) 
    treat_err_2 <- T[-aux_2] - treat_est_2
    #plot(treat_err_2, out_err_2)
    effect_est_2 <- lm(out_err_2 ~ treat_err_2)
    effect_est_2$coef[2]

    # average the estimated effect from each subset
    overall_avg_treat_effect <- mean(c(effect_est_1$coef[2], effect_est_2$coef[2]))
    overall_avg_treat_effect
    effects = c(effects, overall_avg_treat_effect)
}
summary(effects)