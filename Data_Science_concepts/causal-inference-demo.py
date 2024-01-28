# %%
# fully portable example that generates its own data
# uncomment to install dependencies in the notebook instance
#!pip install pandas xgboost

# %% [markdown]
# # Causal modelling outline

# %% [markdown]
# ## General Notes on Causal Analysis
# 
# Everyone in Statistics 101 has been told "correlation is not causation", which remains true.  
# In this case, we are discussing causation, which is the directional effect of one variable on another, as opposed to the bi-directional/symmetric correlation between two variables.
# 
# Also, spelling matters: 
# 
# >"Casual" Analysis is when you put your feet up and do analysis at a leisurely pace.
# 
# >"Causal" Analysis is the examination of cause-and-effect relationships
# 
# Causal analysis was traditionally implemented via experimental design, where the data collection process is determined before the underlying process is observed, which enables a large number of assumptions that make the statistical calculations very convenient. 
# 
# The techniques under discussion here are aim to produce the same quality and interpretation of results gained from an experiment, with the use of observational data where the data was collected without regard for the future analysis, and we cannot enforce the classical assumptions of an experiment. The use of ML eases the number of elements that must be explicitly designed in order to calculate a result while imposing the statistical conditions of a controlled experiment on post hoc data. The details of the framework described here are the setup required to use (correlational) ML models as valid means of computing causal effects.

# %% [markdown]
# Note on the name of this specific causal ML technique: 
# 
# - Data Science/Computer Science discussions/implementations often call it **'Double ML'**, which plainly points out that **what** we are doing is the fitting of two auxiliary ML models (Y ~ X and T ~ X) to construct the effect estimate
# - Econometrics papers seem to favour **'Orthogonal ML'**, which hints at **how** the model-agnostic framework constructs estimates that are free of bias (ie regularization bias) that either single model may have as part of the learned representation
# - Statistics-focused discussions sometimes use **'Debiased ML'**, which highlights the theoretically-proven property that motivates **why** we bother using this framework

# %% [markdown]
# ## Python implementation template

# %% [markdown]
# Roadmap for Double-ML demo notebook
# 
# **Setup**
# 
# * data generating process, so we can explicitly see the underlying mechanisms
# * design of causal outcome `Y`, causal intervention/factor `T`, and nuisance/noise/control factors `X`
# 
# **Application**
# 
# * randomly split the data into two halves, `A` and `B`
# * on split `A`:
#     * train ML model for `T ~ X`
#     * train ML model for `Y ~ X` 
#     * use the models to predict `T`, `Y` using `X` from data split `B` (which was not used for training) 
#     * record the residuals from those predictions (`pred_B - actual_B`)
#     * fit a simple model (Ordinary Least Squares linear regression) for `prediction_resid_Y_B ~ prediction_resid_T_B`, and record the slope
# * repeat for split `B`:
#     * train new models on this half, use them to predict the other half of the data, record residuals, fit unbiased model on residuals from predictions
# * average the two slopes
# * = the expected effect/change on `Y` caused by increasing `T` by 1.0 unit
# * evaluate the implications of an effect of that size, and the relevant range of `T` where it reasonably applies
# * optional: execute this procedure multiple times by re-splitting the data in half differently, collect a range of estimated effects based on this data
# 
# **Explanation of Double Machine Learning procedure**
# 
# * Discussion and theory after the code

# %% [markdown]
# ## Setup

# %%
# needed for Setup
import numpy as np 
import pandas as pd 

# %%
# needed for Application
import xgboost as xg
import matplotlib.pyplot as plt 

# %%
"""
Example scenario: what is the average/overall impact to productivity measured as Sales across our sample if we applied the intervention of adopting Microsoft Teams?
# construct underlying data process with direct causal effects from the Treatment, confounded effects, and nuisance variables and random noise
"""

n = 3000
covariates = dict()

covariates["record_id"] = [500000 + i for i in range(n)] # convenient identifier to follow a particular record

# independent nuisance variable, affects Treatment propensity
covariates["region"] = np.random.choice(['Eastern','Central','Western'], size=n, replace=True, p=None) 

# independent nuisance variable, affects Treatment propensity and Outcome
covariates["experienced"] = np.random.choice([0,1], size=n, replace=True, p=[0.2, 0.8]) 
xp_bonus = 4 

# nuisance variable, not independent, affects Outcome directly
covariates["clients"] = np.maximum(20, np.round(np.random.normal(180, 60, size=n))) * (1 + 0.2*covariates["experienced"]) 

# independent nuisance variable, affects Treatment propensity and Outcome
covariates["tech"] = np.random.choice([0,1], size=n, replace=True, p=[0.33, 0.67]) 
tech_bonus = 3 

# self-selected Treatment variable, not independent of other factors, affects Outcome directly (meaning the other factors )
covariates["latent_propensity"] = 0.25 + (covariates["region"] == 'Eastern') * 0.25 + covariates["tech"] * 0.4 + (covariates["experienced"] * -0.4)
covariates["random_whimsy"] = np.random.uniform(low=0.0, high=1.0, size=n) # unobservable variation, affects Treatment 
covariates["teams"] = np.round(covariates["latent_propensity"] > covariates["random_whimsy"])
teams_bonus = 1
teams_tech_bonus = 3

covariates["random_luck"] = np.random.uniform(low=-10, high=10, size=n) # unobservable variation, affects Outcome

# %% [markdown]
# The below is a Directed Acyclic Graph representing the flow of causality
# 
# * In a simulation like this, we are imposing the mechanics of the process ourselves, so by definition the graph the correct representation of the process
# * In real scenarios, domain-expert knowledge of the relevant process is required to yield the best feasible representation of the process
# * With the modelling framework in the Application section, it is not overly important to have a high quality model of the process
# 
# * Nodes represent variables
# * Edges represent defined relationships between Nodes
# * Edges are all unidirectional because we are imposing a model where outcomes are influenced/caused by an action taken, which was not influenced by the outcome
# * The graph is acyclic for the same reason, as we do not want to model an element in a feedback loop (this would violate the implicit assumption that we can choose to act/intervene of our own free agency rather than our choices being determined by previous events)

# %% [markdown]
# ```mermaid
# ---
# title: "Combined Causal graph"
# ---
# graph LR; 
#     r1[Luck] -.-> Y;
#     x0[Clients] --> Y;
#     T[T = Teams] == direct effect ===> Y[Sales]; 
#     r2[Whimsy] -.-> T;
#     x1[Region] --> T; 
#     x2[Experienced] --> Y & T; 
#     x4[Tech] --> Y & T; 
# ```

# %%
# specify underlying process that leads to Outcomes

# generate sample where Treatment is stochastic (uncertain, but does not follow a uniform distribution)
covariates["sales"] = np.round(covariates["clients"] * ( # effect of clients is not linear wrt the other features
    100 + # linear constant
    covariates["random_luck"] + # random effect 
    covariates["experienced"] * xp_bonus + # direct linear effect
    covariates["teams"] * teams_bonus + # direct linear effect 
    covariates["tech"] * tech_bonus + # direct linear effect
    covariates["tech"] * covariates["teams"] * teams_tech_bonus # linear effect of interaction 
))
"""
specifying the correct parametric functional form for an unbiased estimate would be a huge pain 
Y ~ x0 * (b0 + 0*region + luck + b2*experience + b3*Teams + b4*tech + b5*Teams*tech)

recall, our target is to estimate the linear effect (δ_Y / δ_Teams) = b3 + E( b5 | tech )
and also remember that P(Teams) is not independent of (region, experience, tech, whimsy) in a causal or correlational sense
... better to use machine learning to approximate it
"""

# generate sample where Treatment is universally ignored
covariates["sale_no_teams"] = np.round(covariates["clients"] * (
    100 + 
    covariates["random_luck"] + 
    covariates["experienced"] * xp_bonus + 
    0 * teams_bonus +
    covariates["tech"] * tech_bonus +
    covariates["tech"] * 0 * teams_tech_bonus
))

# generate sample where Treatment is universally applied
covariates["sale_all_teams"] = np.round(covariates["clients"] * (
    100 + 
    covariates["random_luck"] + 
    covariates["experienced"] * xp_bonus + 
    1 * teams_bonus +
    covariates["tech"] * tech_bonus +
    covariates["tech"] * 1 * teams_tech_bonus
))


# %% [markdown]
# Our self-imposed goal for this analysis is to recover the direct effect that 'Teams'  has on 'Sales' outcomes. 
# 
# * Let T represent 'Teams', conventionally called the Treatment factor  
# * Let Y represent 'Sales' as per convention for the Outcome  
# 
# * We must start with the assumption that the flow of causality is from 'Teams' to the outcome of 'Sales' instead of the other way around. 
# * Note that we are not assserting that it has a non-zero magnitude, but usually domain-expertise or other context provides an expectation for that.
# 
# It is trivial to model `Y ~ T`, and it should be fundamental to include other factors that are known to affect the outcome, or 'control for' the nuisance factors
# 
# The difficulty arises when some factors affecting the Outcome also affect the Treatment, called confounders. That is what has been intentionally created in this process.

# %%
feature_df = pd.DataFrame(covariates)
feature_df.shape

# %%
feature_df.head()

# %%
# mean Treatment level
np.mean(feature_df.teams)

# %%
# mean Outcome 
np.mean(feature_df.sales).round()

# %%
# difference in observed Outcome conditioned on Treatment from sample
(np.mean(feature_df.sales.where(feature_df.teams == 1)) - \
 np.mean(feature_df.sales.where(feature_df.teams == 0)) ).round()

# %%
# mean of the per-unit differences between the parallel universes where each treatment is observed
np.mean(feature_df.sale_all_teams - feature_df.sale_no_teams).round()

# %% [markdown]
# Check at this point to see if we have constructed a sufficiently unbalanced dataset where the simple Observed effect is not representative of the True effect.  
# If the estimated Observable effect is off by an order of magnitude, or is so far off as to be directionally-misleading, then you have effectively implemented confounding.  
# Also, generate your data a few times, you should observe a great deal of variation in Observed estimate relative to the True average effect. And yes, on a rare occasion it could be probable for the simple procedure to get an accurate answer.

# %%
# derive any features/transformations for modelling beyond the SQL query
# in particular any explicit type conversions needed by xgboost that Pandas didn't infer 
# feature_df is also used in diagnostic output

feature_df.region = feature_df.region.astype("category") 
feature_df.set_index(keys="record_id", inplace=True, verify_integrity=True)
feature_df.dtypes

# %%
feature_df.index

# %% [markdown]
# ## Application

# %%
# Causal analysis design
# organize data as applicable for current focus

outcome_measure = "sales"
Y: pd.Series = feature_df[outcome_measure] 

causal_factor = "teams" 
T:pd.Series = feature_df[causal_factor]

x_cols = [  
    #'record_id',
    'region', 
    'experienced', 
    'clients', 
    'tech', 
    #'latent_propensity',
    #'random_whimsy', 
    #'random_luck', 
    'teams', 
    'sales',
]
x_cols.remove(outcome_measure)
x_cols.remove(causal_factor) 
X: pd.DataFrame = feature_df[x_cols]

# split data in half for cross-fitting 
N: int = feature_df.shape[0] 
aux_1: np.ndarray = np.random.choice(feature_df.index, int(N * 0.5), replace=False)
aux_2: np.ndarray = np.setdiff1d(np.array(feature_df.index), aux_1)

x_1 = X.loc[aux_1]
x_2 = X.loc[aux_2]
y_1 = Y[aux_1]
y_2 = Y[aux_2]
t_1 = T[aux_1]
t_2 = T[aux_2] 

# %% [markdown]
# Before going any farther, here is a teaser of how the multiple ML models will be used to re-frame our analysis as chunks of the original process.  
# 
# * The model for Treatment and the model for Outcome are expected to be sophisticated predictive models, in particular having robustness to disregard irrelevant noise variables that might be present in the complete set of factors `X`, generally through some form of regularization or explicit variable selection.  T
# * The final unbiased model (OLS linear regression by default) now has the simplified task of describing the relationship of `Y ~ T` through the lens of whatever is resultant from those first two models

# %% [markdown]
# ```mermaid
# ---
# title: DoubleML Causal graph
# ---
# graph LR; 
#     T[Teams] --expectation---> Y[Sales]; 
#     T[Teams] -.residual..-> Y[Sales]; 
#     
#     subgraph Outcome
#         r1[Luck] -.-> Y;
#         x0[Clients] --> Y;
#         c2[Experienced] --> Y;
#         c4[Tech] --> Y; 
#     end
# 
#     subgraph Treatment
#         r2[Whimsy] -.-> T;
#         x1[Region] --> T; 
#         x2[Experienced] --> T; 
#         x4[Tech] --> T; 
#     end
# ```

# %%
# XGBoost model specifications 

# define model for Y ~ X 
model_Y_spec = {
    "booster": "gbtree", 
    "tree_method": "hist", # histogram approximation for splitting high-cardinality vars
    "grow_policy": "lossguide",
    "objective": "reg:squarederror", 
    "num_parallel_tree": 200, # forest size 
    "max_bin": 256, # default 256, used for histogram approximation of high-cardinality vars 
    "max_cat_to_onehot": 1, # 1 => categorical vars use optimal split, not grouped one-hot
    "subsample": 0.66, # subsample of records per-tree
    "colsample_bynode": 1.0, # proportion of column variables to consider per-split
    "max_leaves": 400, # must be less than (2 ^ max_depth) to provide regularization 
    "max_depth": 20, 
    "min_child_weight": 2, # weighted instance count to permit further splits
    "min_split_loss": 100,
    "eta": 1.0, # learning rate per iteration (set to 1.0 when not boosting)
    "lambda": 0.0, # L2 regularization constraint 
    "alpha": 0.0, # L1 regularization constraint 
    #"random_state": 100, 
    "nthread": 2, 
    "verbosity": 1, 
} 

# define model for T ~ X 
model_T_spec = {
    "booster": "gbtree", 
    "tree_method": "hist", # histogram approximation for splitting high-cardinality vars
    "grow_policy": "lossguide",
    "objective": "reg:squarederror", 
    "num_parallel_tree": 200, # forest size 
    "max_bin": 256, # default 256, used for histogram approximation of high-cardinality vars 
    "max_cat_to_onehot": 1, # 1 => categorical vars use optimal split, not grouped one-hot
    "subsample": 0.66, # subsample of records per-tree
    "colsample_bynode": 1, # proportion of column variables to consider per-split
    "max_leaves": 256, # must be less than (2 ^ max_depth) to provide regularization 
    "max_depth": 20, 
    "min_child_weight": 2, # weighted instance count to permit further splits
    #"min_split_loss": 0.005,
    "eta": 1.0, # learning rate per iteration (set to 1.0 when not boosting)
    "lambda": 0.0, # L2 regularization constraint 
    "alpha": 0.0, # L1 regularization constraint 
    #"random_state": 100, 
    "nthread": 2, 
    "verbosity": 2, 
} 

# define model for err_Y ~ err_T
# linear regression of err_Y = m * err_T + c
model_R_spec = {
    "booster": "gblinear", 
    "updater": "coord_descent", 
    "objective": "reg:squarederror", # need to make all treatment comparisons valid to use with least-squares objective
    "top_k": 0, # number of features to keep from feature selection, default=0 to skip feature selection 
    "eta": 1.0, # learning rate per iteration (set to 1.0 when not boosting)
    "lambda": 0.0, # L2 regularization constraint 
    "alpha": 0.0, # L1 regularization constraint 
    #"random_state": 100, 
    "nthread": 2, 
    "verbosity": 2, 
} 

# %%
def train_aux_models(x_train, y_train, t_train, x_pred, y_pred, t_pred, model_Y_params, model_T_params):
    # fit Y_train ~ X_train
    m_Y: xg.Booster = xg.train(
        params=model_Y_params, 
        dtrain=xg.DMatrix(data=x_train, label=y_train, enable_categorical=True), num_boost_round=1, 
    ) 
    # predict Y on X_pred
    y_pred_estimated = m_Y.predict(data=xg.DMatrix(data=x_pred, label=y_pred, enable_categorical=True), output_margin=True)
    
    # fit T_train ~ X_train
    m_T: xg.Booster = xg.train(
        params=model_T_params, 
        dtrain=xg.DMatrix(data=x_train, label=t_train, enable_categorical=True), num_boost_round=1, 
    ) 
    # predict T on X_pred
    t_pred_estimated = m_T.predict(data=xg.DMatrix(data=x_pred, label=t_pred, enable_categorical=True), output_margin=True)
    
    # collect residuals 
    resids = pd.DataFrame() 
    resids['y_actual'] = y_pred
    resids['y_pred'] = y_pred_estimated
    resids['y_resid'] = (y_pred_estimated - y_pred) 

    resids['t_actual'] = t_pred
    resids['t_pred'] = t_pred_estimated
    resids['t_resid'] = (t_pred_estimated - t_pred) 

    return resids, m_Y, m_T


# %%
# fit Y1 ~ X1
# predict on X2, err_Y2 = (pred - Y2) 
# fit T1 ~ X1
# predict on X2, err_T2 = (pred - T2) 
# collect residuals 
cross_fit_1 = train_aux_models(
    x_train=x_1, y_train=y_1, t_train=t_1, 
    x_pred=x_2, y_pred=y_2, t_pred=t_2, 
    model_Y_params=model_Y_spec, model_T_params=model_T_spec
)
resid_regression_1: xg.Booster = xg.train(
    params=model_R_spec, 
    dtrain=xg.DMatrix(data=cross_fit_1[0]['t_resid'], label=cross_fit_1[0]['y_resid']), num_boost_round=1, 
) 
coef_1 = float((resid_regression_1.get_dump()[0]).split('\n')[3])
coef_1

# %%
cross_fit_1[0].head().round(1)

# %%
# fit Y2 ~ X2
# predict on X1, err_Y1 = (pred - Y1) 
# fit T2 ~ X2
# predict on X1, err_T1 = (pred - T1) 
# collect residuals 
cross_fit_2 = train_aux_models(
    x_train=x_2, y_train=y_2, t_train=t_2, 
    x_pred=x_1, y_pred=y_1, t_pred=t_1, 
    model_Y_params=model_Y_spec, model_T_params=model_T_spec
)
resid_regression_2: xg.Booster = xg.train(
    params=model_R_spec, 
    dtrain=xg.DMatrix(data=cross_fit_2[0]['t_resid'], label=cross_fit_2[0]['y_resid']), num_boost_round=1, 
) 
coef_2 = float((resid_regression_2.get_dump()[0]).split('\n')[3])
coef_2

# %%
cross_fit_2[0].head().round(1)

# %%
# calculate causal effect size
# standard template for binary and continuous values of T
print(f"causal factor: {causal_factor}\nest. effect size: {round((coef_1 + coef_2) / 2, ndigits=1)}\n")

# %%
# test more splits to test sensitivity

estimates = []

for i in range(25):

    aux_1: np.ndarray = np.random.choice(feature_df.index, int(N * 0.5), replace=False)
    aux_2: np.ndarray = np.setdiff1d(np.array(feature_df.index), aux_1)

    x_1 = X.loc[aux_1]
    x_2 = X.loc[aux_2]
    y_1 = Y[aux_1]
    y_2 = Y[aux_2]
    t_1 = T[aux_1]
    t_2 = T[aux_2] 
    
    cross_fit_1 = train_aux_models(
        x_train=x_1, y_train=y_1, t_train=t_1, 
        x_pred=x_2, y_pred=y_2, t_pred=t_2, 
        model_Y_params=model_Y_spec, model_T_params=model_T_spec
    )
    resid_regression_1: xg.Booster = xg.train(
        params=model_R_spec, 
        dtrain=xg.DMatrix(data=cross_fit_1[0]['t_resid'], label=cross_fit_1[0]['y_resid']), num_boost_round=1, 
    ) 
    coef_1 = float((resid_regression_1.get_dump()[0]).split('\n')[3])
    cross_fit_2 = train_aux_models(
        x_train=x_2, y_train=y_2, t_train=t_2, 
        x_pred=x_1, y_pred=y_1, t_pred=t_1, 
        model_Y_params=model_Y_spec, model_T_params=model_T_spec
    )
    resid_regression_2: xg.Booster = xg.train(
        params=model_R_spec, 
        dtrain=xg.DMatrix(data=cross_fit_2[0]['t_resid'], label=cross_fit_2[0]['y_resid']), num_boost_round=1, 
    ) 
    coef_2 = float((resid_regression_2.get_dump()[0]).split('\n')[3])
    
    estimates.append(round((coef_1 + coef_2) / 2, ndigits=1))


# %%
np.mean(estimates)

# %%
sorted(estimates)

# %%
fig, ax = plt.subplots()

ax.scatter(x=T, y=Y, alpha=0.2)
ax.set(xlim=(0, 1), ylim=(0, 40_000))

# %%
resid_regression_confounded: xg.Booster = xg.train(
    params=model_R_spec, 
    dtrain=xg.DMatrix(data=T, label=Y), num_boost_round=1, 
) 
confounded_coef = float((resid_regression_confounded.get_dump()[0]).split('\n')[3])
confounded_coef

# %%
# plot errors in predicted Y ~ X wrt errors of predicting T ~ X
# -ve vertical means under-estimated Y, +ve vertical means over-estimated
# -ve horizontal means under-estimated T, +ve horizontal means over-estimated T

fig, ax = plt.subplots()
aux_resid = pd.concat((cross_fit_1[0], cross_fit_2[0]))
aux_resid["direction"] = np.sign(aux_resid.y_resid * aux_resid.t_resid)

plt.axvline(x=0, color='black') 
plt.axhline(y=0, color='black') 
ax.set(xlim=(-1.1, 1.1), ylim=(-10_000, 10_000)) 
ax.scatter(x=aux_resid.t_resid, y=aux_resid.y_resid, alpha=0.2) 

# interpret: upper-right means Y turned out higher than expected, while T was higher than expected
# lower-left means Y was below expectations, for the cases where T was also lower than expected

# %%
max_resids = aux_resid[abs(aux_resid.t_resid) > 0.15].sort_values(by="t_resid")
max_resids

# %%
feature_df.loc[max_resids.axes[0][0]]

# %%
# model diagnostics
model_c1_y = cross_fit_1[1].trees_to_dataframe()
model_c1_t = cross_fit_1[2].trees_to_dataframe()
model_c2_y = cross_fit_2[1].trees_to_dataframe()
model_c2_t = cross_fit_2[2].trees_to_dataframe()

# %%
# check average leaves per tree in a forest relative to model constraints
{"Y":[
    model_Y_spec["max_leaves"], 
    round(aux_1.shape[0] / model_Y_spec["min_child_weight"]), # max leaves if splitting constrained by min child size
    model_c1_y[model_c1_y.Feature == 'Leaf'].shape[0] / 200,
    model_c2_y[model_c2_y.Feature == 'Leaf'].shape[0] / 200,
], 
"T":[
    model_T_spec["max_leaves"], 
    round(aux_1.shape[0] / model_T_spec["min_child_weight"]), 
    model_c1_t[model_c1_t.Feature == 'Leaf'].shape[0] / 200, 
    model_c2_t[model_c2_t.Feature == 'Leaf'].shape[0] / 200,
]
}

# %%
# check that RMSE is less than standard deviation of the raw data (variance explained)
# check that predictions standard deviation compared to raw data (regularized/conservative models will be less than raw data)
[
    round(np.std(aux_resid.y_actual)),
    round(np.std(aux_resid.y_pred)),
    round(np.mean(np.sqrt(aux_resid.y_resid ** 2))),
    
    round(np.std(aux_resid.t_actual), ndigits=3),
    round(np.std(aux_resid.t_pred), ndigits=3),
    round(np.mean(np.sqrt(aux_resid.t_resid ** 2)), ndigits=3),
]

# %%
# Y ~ X diagnostics
xg.plot_importance(cross_fit_1[1])
xg.plot_importance(cross_fit_2[1])

# %%
# T ~ X diagnostics
xg.plot_importance(cross_fit_1[2])
xg.plot_importance(cross_fit_2[2])

# %% [markdown]
# ## Explanation of Double Machine Learning procedure

# %% [markdown]
# Recap of the simulated example, where a (hopefully) decent estimate of the effect was recovered by digging it out of a pile of residuals from six independently trained models (three designs, across two folds of data).  
# 

# %% [markdown]
# ```mermaid
# ---
# title: "Combined Causal graph"
# ---
# graph LR; 
#     r1[Luck] -.-> Y;
#     x0[Clients] --> Y;
#     T[Teams] == direct effect ===> Y[Sales]; 
#     r2[Whimsy] -.-> T;
#     x1[Region] --> T; 
#     x2[Experienced] --> Y & T; 
#     x4[Tech] --> Y & T; 
# ```

# %% [markdown]
# The biggest obstacle to getting an unbiased estimate of the effect `T -> Y` was that some of the nuisance factors that affect `Y` directly, also affect `Y` indirectly via their effect on `T`.  
# For a conventional predictive model, this does not pose a threat to predictive performance; all the information needed to predict `Y` is available. The issue is that the internal representation of the effect that `T` has on `Y` is undefined or unstable for most models under these circumstances. Using techniques like SHAP to explain the model will expose this internal representation for inspection, but does not make it any more reliable in representing the effect-of-interest. If the model can reduce its loss metric by excluding `T` as a factor, that is what SHAP will display, which does not solve the task of quantifying the effect of `T`.

# %% [markdown]
# In terms of the steps of the Double ML algorithm, here is how the useful modelling of this effect was accomplished: 
# 
# 1. By modelling `T ~ X`, we are creating an expectation of any non-random patterns in the propensity for any particular value `T`.
#     * In other words, a predictive model to account for any self-selection bias that deviates the Random assignment of `T`
#     * If the assignment of treatments was uniformly random, or random within stratifications of `X`, the model would give an expectation of the mean value of `T`, and have essentially no predictive value. This would be the ideal, a natural experiment. 
#     * Conversely, if the `T` for an individual was totally deterministic based on `X`, a suitably performant model could achieve perfect predictive value. That means you also have no contrast between different outcomes caused by different values of `T`, so the effect of `T -> Y` is unrecoverable/undefinable from your data
# 
# 2. By modelling `Y ~ X`, we are creating an expectation of the outcome that accounts for all the available information, except for the value of `T` 
#     * In other words, controlling for all the direct effects of `X -> Y`, but independent of the effect of `T` 
#     * if we were to know that predictive value would not be increased by the inclusion of `T` then it should be intuitive that your data does not contain evidence that `T` has a non-zero effect on `Y`
# 
# 3. By testing the prediction on a subset of data mutually-exclusive from the training subset, we get a decent chance of reflecting the predictive value of the model
#     * k-fold cross-validation is nothing novel, but consider that in a case of perhaps five-fold CV, each iteration fitted overlaps 75% of its training data with the training sets for each of the other folds, meaning that the patterns learned will be correlated to an extent
#     * if we are after an unbiased estimate of an effect which is learned, interpreting the observed variance of k correlated effect-estimates is non-trivial. 
#     * Estimates yielded from models with mutually-exclusive train and test sets are statistically independent and can be averaged, just like doing two independent experiments. If the training and testing samples are the same size, you don't even need a weighted average of the estimates. Therefore, the lowest-effort way to extract information from your entire dataset is to do two folds
# 
# 4. Linear regression of the prediction: `error_Y ~ error_T`
#     * The prediction errors from `T ~ X` represent the actual values of `T`, after conditioning on a given `X`, and therefore are the component that is statistically independent of/controlled for `X`
#     * The prediction errors from `Y ~ X` represent the component of `Y` that is unexplainable based on the observable `X`, in other words the variation in `Y` after controlling for `X`
#     * Explicitly, the prediction residuals from `Y ~ X` are the variation in `Y` that is explained by some combination of the effect of `T`, along with the rest of the unobservable noise
#     * We can now relate "residual variation in `Y` caused by `T` plus random noise" with respect to the "value of `T` that is independent of `X`"
#     * ordinary least-squares linear regression is a convenient and simple method to quantify and interpret that relationship, and does not introduce any statistical bias in its estimation
# 

# %% [markdown]
# ```mermaid
# ---
# title: DoubleML Causal graph
# ---
# graph LR; 
#     T[Teams] --expectation---> Y[Sales]; 
#     T[Teams] -.residual..-> Y[Sales]; 
#     
#     subgraph Outcome
#         r1[Luck] -.-> Y;
#         x0[Clients] --> Y;
#         c2[Experienced] --> Y;
#         c4[Tech] --> Y; 
#     end
# 
#     subgraph Treatment
#         r2[Whimsy] -.-> T;
#         x1[Region] --> T; 
#         x2[Experienced] --> T; 
#         x4[Tech] --> T; 
#     end
# ```

# %% [markdown]
# ### Motivating Issues
# 
# * a randomized controlled trial assigns a Treatment/intervening action `T` to each subject `i`
# * this is done prior to any record of the Outcome `Y`, and so is logically independent/unaffected by the eventual Outcome
# 
# * uncontrolled observational data may have record of many subjects, which `T` they were affected by, and their other identifying factors `X` 
# * however, there is some likelihood that the data is the result of a process where subjects were matched to their `T` non-uniformly, meaning that there could be a bias in the prevalence of a particular `T` being applied, with a link to some other factor(s) in `X`
# * since `X` contains factors that are believed relevant to the Outcome, those factors confound the causal effect that `T` could have on `Y`
# * if one was to estimate `E(Y|T,X)` with a single model, the estimated effects for factors in `X` contain the conditional effect `P(Y=y | X=x) * P(Y=y | T=t)` where `P(Y=y | T=t)` can also be expressed as some other `P'(Y=y | X=x)`
# 
# * to add one more layer of complication, assuming that `X` is necessarily of high-dimension relative to the complexity of the process and the number of records available, modern machine learning recommends various forms of regularization
# * it is well established that this offers a reduction in variance/instability in exchange for incurring some bias to the estimated contributions of each parameter, which is highly beneficial for predictive applications
# * this is in fact another element that obfuscates the precise contribution/effect of each individual factor
# 
# ### Algorithm
# 
# * thanks to many very clever statisticians, there is a theoretically-sound process to extract an unbiased estimate of a particular effect
# * the resulting implementation is astonishingly elegant: 
# 
# 1. use half `a` of your observed data to train two auxilliary models
# 2. train your ML algorithm of choice to model `T ~ X`, and then train an ML algorithm for `Y ~ X` as usual
# 3. use those trained models to predict `T` and `Y`, respectively based on `X` for the half `b` of your observation data
# 4. with the residuals from predicting (the omission of `T` when modelling `Y` is assumed to contribute some component of these residuals), linearly regress `resid_Y ~ resid_T` 
# 5. the resulting slope is an unbiased estimate of the effect of `T` on `Y` (conditioned-upon/orthogonal to the effects of `X` on `Y` and `X` on `T`)
# 6. now flip and repeat the procedure, training the two auxilliary models on the data of half `b`, and collecting the residuals from predicting on half `a` of your data set, and do the same regression
# 7. simply average those two slope estimates, because they come about from models trained on mutually-exclusive samples
# 
# **Results:** 
# 
# * You now have an estimated effect of `T` on `Y`
#     * interpretted as linear delta `Y` caused by delta `T` (valid for comparing binary or cardinal values of `T`) 
#     * isolated from the nuisance/confounding factors `X` that are accounted for by each of the two models
#     * based on your entire usable sample of data due to the cross-fitting (mitigating any bias possibly introduced by which data points ended up in each training/testing portion) 
#     * The purpose of using residuals of the predictions of two unrelated models was for the purpose of neutralizing issues arising from whatever regularization bias is introduced by either of the two models, because the models themselves are of little consequence so long as they can each be assumed to reasonably approximate their underlying processes
# 
# 
# * Please see the 2016 paper by Chernuzhukov et al for the proper explanation of the theoretical foundations: https://arxiv.org/abs/1608.00060v6
# 
# 
# **How to define/test Validity of Results:**
# 
# https://matheusfacure.github.io/python-causality-handbook/22-Debiased-Orthogonal-Machine-Learning.html
# 
# 

# %% [markdown]
# ### Motivating Case Study
# 
# Imagine a generic scenario for causal inference in a retail context: Head Office created a training course for its dedicated force of Sales Representatives, and wants to know if that intervention is effective (how did it influence outcomes, direction and magnitude).

# %% [markdown]
# #### **Classical Statistical design**
# 
# For a controlled experiment, take a representative sample of Sales Reps, and randomly assign them with uniform probability to either Training or No Training. For additional control, stratify the random assignment by a relevant factor; consider "baseline Sales performance" might affect the outcome of Sales performance after Training
# 
# Visually, we have a sample of Reps {A, B, C, D, E, F}
# A, D are high performers, B, E represent the middle, and C, F are struggling. One from each pair assigned to each condition.
# The true outcome is that every segment recieving Training averages +2 over the outcomes of their counterparts with No Training, and that is easy to recover from the experimental data with a very simple calculation.

# %% [markdown]
# #### **Modern Solution to Modern Problems**
# 
# Now, imagine a retail business not operated by a statistician, where actions are taken without a priori regard for the analytical design. 
# In this parallel universe, the same Training was developed, and offered optionally to sales Reps.
# 
# Also, the stratification of high/middle/low performers is represented by 25 factors in the raw data, from among 200 factors in the available Sales Rep Profile.
# 
# Finally, the Sales Reps do not behave according to a uniform distribution independent of their Profile; struggling Reps sought out the Training more frequently, and the ones performing well didn't, even if it would have benefitted them all just the same.
# 
# The simplest calculation of taking the average outcome and contrasting between the two Training options does recover a positive effect from the Training of +0.66. This is a biased underestimate that might dramatically change how the value of the Training is assessed. And in yet another universe, the top-performing Reps might be the ones to seeking Training more frequently, and that estimate could be very over-inflated. 
# 
# The next most straight-forward approach might be to use a robust model to represent the relationship between the Rep Profile (plus the factor of their Training), let the model tell you which factors matter, and check the sensitivity of the outcome with respect to the factor for Training (ie SHAP value contribution). You can even consider that metric when training the model on bootstrap sampling or permutations of the data set to assess the stability of that estimate, or k-fold cross-validation to evaluate how robust the model's predictive performance is. 
# 
# And those are theoretically sound approaches for extracting the weighting of the Training factor learned by the model, and indeed demonstrating that the model is robust for predicting outcomes. Unfortunately, robust predictive models not only have a theoretical probability of a biased estimate of the causal effect, but a near-certainty in practice. Aspects of regularization/pruning/dropout/feature selection are great for robust predictions for complex models on high-dimensional data. And they inherently bias the estimated contributions of each particular factor. Among 201 factors to model an outcome, there is no assurance that the factor of interest won't get ignored entirely. 
# 
# (Unless that single feature has such a dominating impact on the outcome as to be certainly included, but then you probably don't need to go any further in your data mining to make a conclusion. Relevant XKCD: https://www.explainxkcd.com/wiki/index.php/2400:_Statistics)
# 
# There is a theory for accounting for non-random self-selection on observational data. Inverse-Frequency Weighting (propensity-matching) seeks to re-weight the observations of each value of `T` being contrasted, based on frequency of appearing in the observed data. This is valid, and feasible if each observation is described by a profile `X` composed of a small handful of low-cardinality features. Impracticality aside for very large datasets of high-dimensional observations, the inverse-frequency weighting leads to numerical instability when observations are sparsely distributed across the sample space. AKA curse of dimensionality, usually approached with manually feature-engineering from domain expertise or learning a lower-dimension/lower-cardinality representation of key attributes, until it gets simple enough for the propensity-matching to be feasible, and then the simple unbiased estimate of the contrasted effect can be calculated.
# 
# If you take from that the steps of: 
#     1. learning a compressed representation of the observations with respect to `X`
#     2. using a formula-based representation of propensity the of `T`
#     3. using that to adjust the observed `Y` so that an unbiased effect can be recovered
# We are most of the way to a workable solution. Though it would be quite nice not to have to disregard any model-based data-mining that we are going to do anyway, or if there was more flexibilty in how to represent the data. And not be limited to evaluating strictly discrete, binary (A/B-test) effects.
# 
# If you are still with me, you are likely comfortable with modern modelling techniques in a big-data context, have no fear of continuous-valued factors or hypothesis-testing, and may be working on applications where it's not feasible to conduct the intervention as an experiment (limitations of budget, ethics, or the laws of physics). The idea of a +2 percentage point increase in conversions sounds like an amazing ROI for a program that cost 1% of the sales-effectiveness budget. And beyond constructing a decent predictive model, you (or your audience) care to know whether the unbiased causal effect of one factor among 201 is +0.5% vs +2%. 

# %% [markdown]
# #### **Double-Debiased Machine Learning framework**
# 
# Model the expected Training scenario wrt 200-factor Rep Profile, which will learn a representation from the Profile that predicts 'low performers' as more likely to take part in the Training program. 
# 
# Model the expected Outcome wrt 200-factor Rep Profile, which will learn to predict Reps with higher past-performance as having higher expected Outcomes. 
# 
# Plot the prediction errors/residuals for Outcomes with respect to the prediction error for the Training scenario
# 
# Assuming both predictive models are quite strong, the majority of residual pairs should be clustered with reasonable proximity to the origin. 
# 
# If the model is able to perfectly predict `Y` ~ `X` without knowing `T`, then the Y-residuals will be on a horizontal line through the origin, scattered across the whole range, which is interpreted as zero effect caused by `T`. In this case you can be confident that the `T` being considered has no impact on `Y` ... and also confident you have everything else that has predictive value.
# 
# If somehow your model for `T` ~ `X` perfectly predicts every `T` with 100% confidence, the plotted residual pairs will be a vertical line through the origin. This undefined slope could be the result of a case where the choice of `T` is deterministic based on some elements of `X`, which means you can't make a valid estimate of the effect of `T` that generalizes across your sample space. 
# 
# Beyond being astonishingly unlikely in this application, these pitfalls don't violate any intuition about training your dual predictive models. The normal conclusion would be over-fitting or unsuitable data; one response is stronger regularization for better generalization of predictions.
# 
# 
# If a higher-performing Rep skips the Training, the model can be expected to have a small-magnitude residual, slightly positive unless the model predicts 100% chance of No Training; 
# If the same Rep has an objectively high Outcome, that's also an easy low-residual prediction. But the model of Outcome doesn't see the Training factor, and if the Rep's performance falls short of the expectation due to this unseen factor, then the prediction should be an overestimate, producing a positive residual to match. -> positive slope from this point back to the origin.
# 
# If a higher-performing Rep opts into the Training, that is more unexpected, leading to a larger-magnitude error in the negative direction. 
# This same Rep would already be expected to have a high Outcome, but beside their comparable peers, if the unseen effect of Training boosts their performance even higher than expected across the sample of Trained + Not-Trained high-performers, they will still lead to a negative residual from the under-estimate. Still contributing to a positive slope through the origin. 
# 

# %% [markdown]
# **Remarks:**
# 
# The scale of these residuals has nothing to do with the learned representation/contribution of any particular factors in either of the two models, just the predictive performance. The factor for `T` as an input doesn't get learned at all. 
# 
# `X` is assumed to contain to contain every relevant factor for predicting both `Y` and `T`. Implicit variable-selection in the two auxillary models can handle any excess (and is recommended, because it's realistic to expect it will not be exactly the same set of factors affecting both). 
# 
# This process does not discover/identify which factor has a causal effect, nor does it distinguish the direction of a causal effect. The foundation is asserting that `T` has a directed causal effect on `Y`, and that by knowing all the other relevant factors in a model that is capable of representing the process of `X` -> `Y`, the direct causal effect of `T` is the dominant component of the remaining error (because any potential indirect causal effects of `X` via `T` are accounted for)
# 
# If this method were applied to a data set that was constructed from a trial where `T` was assigned independent of any elements of `X`, and the model for `T` ~ `X` was robust enough not to overfit on noise, it should produce essentially constant outputs. 
# Example: for balanced uniform assignment of binary `T` = 0 or 1, predicted `T` = 0.5, and the resulting residuals would be +0.5 or -0.5, respectively, and the slope would represent the difference in `Y` residuals, which is dominated by the effect of `T`, divided by that support range of one. In other words, a Randomized Controlled Trial could be seen as a special/trivial case of this framework

# %% [markdown]
# ```mermaid
# ---
# title: Generic Cause-and-Effect process map
# ---
# graph LR;
#     
#     X_T --> T; 
#     T --> Y; 
#     X_C --> Y; 
#     X_C --> T; 
#     X_Y ---> Y; 
# ```

# %% [markdown]
# Denoting factors affecting `Y` as `X_Y`  
# Denoting factors affecting `T` as `X_T`  
# Denoting factors affecting both `Y` and `T` as `X_C` (confounders)  
# `X` as discussed above contains `{X_T, X_C, X_Y}`   
# 
# Model `T ~ X` should end up selecting features in `X_T` and `X_C`, and ignoring `X_Y`  
# Model `Y ~ X` should end up selecting features in `X_Y` and `X_C`, and ignoring `X_T`  


