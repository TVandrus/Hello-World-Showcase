# Causal analysis to recover model effects 

import os, random 
import duckdb as dd
import xgboost as xg 
import pandas as pd 

# single tree 
model_tree_spec = {
    "booster": "gbtree", 
    "tree_method": "hist", # histogram approximation for splitting high-cardinality vars
    "objective": "reg:squarederror", 
    "grow_policy": "lossguide", # 'depthwise' or 'lossguide'
    "num_parallel_tree": 1, # forest size 
    "subsample": 1.0, # subsample of records 
    "min_child_weight": 5, # weighted instance count to permit further splits
    "colsample_bynode": 1.0, # proportion of column variables to consider per-split
    "max_bin": 256, # default 256, used for histogram approximation of high-cardinality vars 
    "max_cat_to_onehot": 1, # categorical vars use optimal split 
    "max_depth": 10, 
    "max_leaves": 500, # must be less than (2 ^ max_depth) to provide regularization 
    #"monotone_constraints": [],
    #"interaction_constraints": [], 
    "gamma": 0, # min loss required to permit further splits
    "eta": 1, # learning rate, set = 1.0 if not boosting
    "lambda": 0, # L2 regularization parameter 
    "alpha": 0, # L1 regularization parameter
    "random_state": 227, 
    "nthread": 2, 
    "verbosity": 2, 
} 


# double-debiased ML format: 
"""
model 1: Tree(p1): X -> Y; Pred(p2)
model 2: Tree(p1): X -> T; Pred(p2) 
model 3: Tree(p2): X -> Y; Pred(p1)
model 4: Tree(p2): X -> T; Pred(p1)
model 5: LM: Residual(model 1) ~ Residual(model 2)
model 6: LM: Residual(model 3) ~ Residual(model 4)
"""

# split data in half, partitions 1 & 2 

raw_data = [] # get df of simulated data from DuckDB

x_features = [] 

X = raw_data.filter(x_features)
T = raw_data.action_var
Y = raw_data.response_var 

n = X.shape[0]
sample_1 = random.sample(range(0, n), int(n/2))
sample_2 = set(range(0, n)).difference(sample_1)


tree_1 = xg.train(
    params=model_tree_spec, 
    dtrain=xg.DMatrix(data=X[sample_1], label=Y[sample_2], enable_categorical=True), 
    num_boost_round=1
)

tree_2 = xg.train(
    params=model_tree_spec, 
    dtrain=xg.DMatrix(data=X[sample_1], label=T[sample_2], enable_categorical=True), 
    num_boost_round=1
)

tree_3 = xg.train(
    params=model_tree_spec, 
    dtrain=xg.DMatrix(data=X[sample_2], label=Y[sample_1], enable_categorical=True), 
    num_boost_round=1
)

tree_4 = xg.train(
    params=model_tree_spec, 
    dtrain=xg.DMatrix(data=X[sample_2], label=T[sample_1], enable_categorical=True), 
    num_boost_round=1
)