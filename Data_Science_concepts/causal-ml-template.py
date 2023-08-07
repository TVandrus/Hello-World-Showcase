import os, random, math
import numpy as np
import pandas as pd 
import xgboost as xg
import shap

import matplotlib.pyplot as plt
import matplotlib 
matplotlib.use('QtAgg')

working_dir = "C:/Users/tvand/Sandbox/DataStorage/RawData/lendingclub-loan-data/"

# extract
raw_data = working_dir + "lc_loan.csv"
raw_df = pd.read_csv(filepath_or_buffer=raw_data, header=0, sep=",", quotechar="\"", low_memory=False) 

raw_df.columns 
raw_df.shape 

# transform 
raw_df.replace([np.inf, np.nan], None)

x_cols = [
    "term", "int_rate", 
    #"installment", 
    "grade", "sub_grade","emp_length", "home_ownership", 
    "annual_inc", "verification_status", "loan_status", "pymnt_plan", "addr_state", "dti", 
    "delinq_2yrs","earliest_cr_line", "inq_last_6mths", "mths_since_last_delinq", 
    "mths_since_last_record", "open_acc", "pub_rec", "revol_bal","revol_util", "total_acc", 
    "initial_list_status", "policy_code", "application_type","all_util", "inq_last_12m"
]

raw_df.term = raw_df.term.astype("category")
raw_df.grade = raw_df.grade.astype("category")
raw_df.sub_grade = raw_df.sub_grade.astype("category")
raw_df.emp_length = raw_df.emp_length.astype("category")
raw_df.home_ownership = raw_df.home_ownership.astype("category")
raw_df.verification_status = raw_df.verification_status.astype("category")
raw_df.loan_status = raw_df.loan_status.astype("category")
raw_df.pymnt_plan = raw_df.pymnt_plan.astype("category")
raw_df.addr_state = raw_df.addr_state.astype("category")
raw_df.earliest_cr_line = raw_df.earliest_cr_line.astype("category")
raw_df.initial_list_status = raw_df.initial_list_status.astype("category")
raw_df.application_type = raw_df.application_type.astype("category")


# load - save transformed data as parquet or binary



# model engineering 
n = raw_df.shape[0]

aux_1 = np.random.choice(n-1, int(n * 0.75), replace=False)
aux_2 = np.setdiff1d(np.array(range(n)), aux_1)

x_1 = (raw_df[x_cols]).iloc[aux_1]
x_2 = (raw_df[x_cols]).iloc[aux_2]
y_1 = raw_df.loan_amnt[aux_1]
y_2 = raw_df.loan_amnt[aux_2]

# standard predictive ML model
m_0_path = working_dir + "model_0.json"
model_0_spec = {
    "booster": "gbtree", 
    "tree_method": "hist", # histogram approximation for splitting high-cardinality vars
    "num_parallel_tree": 50, # forest size 
    "subsample": 0.66, # subsample of records 
    "objective": "reg:squarederror", 
    "min_child_weight": 7, # weighted instance count to permit further splits
    "colsample_bynode": 0.3, # proportion of column variables to consider per-split
    "max_bin": 256, # default 256, used for histogram approximation of high-cardinality vars 
    "max_cat_to_onehot": 1, # categorical vars use optimal split 
    "max_depth": 7, 
    "max_leaves": 100, # must be less than (2 ^ max_depth) to provide regularization 
    "random_state": 227, 
    "nthread": 6, 
    "verbosity": 2, 
} 
m_0 = xg.train(
    params=model_0_spec, 
    dtrain=xg.DMatrix(data=x_1, label=y_1, enable_categorical=True), 
    num_boost_round=1
)
m_0.save_model(m_0_path)

y_pred = m_0.predict(xg.DMatrix(data=x_2, enable_categorical=True))
resid = pd.DataFrame({"y_pred": y_pred, "y_test": y_2, "err": y_pred - y_2})

shap_values = m_0.predict(xg.DMatrix(data=x_2, enable_categorical=True), pred_contribs=True)
shap.summary_plot(shap_values[:, :-1], x_2, plot_type="bar")


# unregularized single tree
m_1_path = working_dir + "model_1.json"
model_1_spec = {
    "booster": "gbtree", 
    "tree_method": "hist", # histogram approximation for splitting high-cardinality vars
    "num_parallel_tree": 1, # forest size 
    #"subsample": 1.0, # subsample of records 
    "objective": "reg:squarederror", 
    "min_child_weight": 5, # weighted instance count to permit further splits
    #"colsample_bynode": 1.0, # proportion of column variables to consider per-split
    "max_bin": 256, # default 256, used for histogram approximation of high-cardinality vars 
    "max_cat_to_onehot": 1, # categorical vars use optimal split 
    "max_depth": 10, 
    #"max_leaves": 1000, # must be less than (2 ^ max_depth) to provide regularization 
    "random_state": 227, 
    "nthread": 1, 
    "verbosity": 1, 
} 
m_1 = xg.train(
    params=model_1_spec, 
    dtrain=xg.DMatrix(data=x_1, label=y_1, enable_categorical=True), 
    num_boost_round=1
)
m_1.save_model(m_1_path)


# double-debiased ML for causal effect estimation 
model_2y_spec = {
    "booster": "gbtree", 
    "tree_method": "hist", # histogram approximation for splitting high-cardinality vars
    "num_parallel_tree": 50, # forest size 
    "subsample": 0.66, # subsample of records 
    "objective": "reg:squarederror", 
    "min_child_weight": 7, # weighted instance count to permit further splits
    "colsample_bynode": 0.3, # proportion of column variables to consider per-split
    "max_bin": 256, # default 256, used for histogram approximation of high-cardinality vars 
    "max_cat_to_onehot": 1, # categorical vars use optimal split 
    "max_depth": 7, 
    "max_leaves": 100, # must be less than (2 ^ max_depth) to provide regularization 
    "random_state": 227, 
    "nthread": 6, 
    "verbosity": 2, 
} 
model_2t_spec = {
    "booster": "gbtree", 
    "tree_method": "hist", # histogram approximation for splitting high-cardinality vars
    "num_parallel_tree": 50, # forest size 
    "subsample": 0.66, # subsample of records 
    "objective": "multi:softmax", 
    "min_child_weight": 7, # weighted instance count to permit further splits
    "colsample_bynode": 0.3, # proportion of column variables to consider per-split
    "max_bin": 256, # default 256, used for histogram approximation of high-cardinality vars 
    "max_cat_to_onehot": 1, # categorical vars use optimal split 
    "max_depth": 7, 
    "max_leaves": 100, # must be less than (2 ^ max_depth) to provide regularization 
    "random_state": 227, 
    "nthread": 6, 
    "verbosity": 2, 
} 
# E(Y|X) 
m_2y = xg.train(
    params=model_2y_spec, 
    dtrain=xg.DMatrix(data=x_1.loc[:, x_1.columns != 'home_ownership'], label=y_1, enable_categorical=True), 
    num_boost_round=1
)
# E(T|X) 
m_2t = xg.train(
    params=model_2t_spec, 
    dtrain=xg.DMatrix(data=x_1.loc[:, x_1.columns != 'home_ownership'], label=x_1.home_ownership, enable_categorical=True), 
    num_boost_round=1
)
# need to define residuals for E(T|X) 


