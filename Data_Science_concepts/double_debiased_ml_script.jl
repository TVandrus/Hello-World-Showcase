using XGBoost, DuckDB, DataFrames, CategoricalArrays

db_loc = "Data_Science_Concepts/__local_artifacts__/portable.duckdb";
	# retrieve data 
db = DuckDB.open(db_loc)
con = DuckDB.connect(db)
results = DuckDB.execute(con, "select * from sim.archery")
DuckDB.disconnect(con)
DuckDB.close(db)

feature_df = DuckDB.toDataFrame(results);

feature_df.skill = categorical(feature_df.skill)

Y = feature_df.:score;
T = feature_df.:bow;
x_cols = [
	:skill,
	:strength, 
	:range,
	:arrow,
	:wind, 
]
X = feature_df[!, x_cols]

# specify models
# Y ~ X
Y_model_params = (
	booster="gbtree", 
	objective="binary:logistic",
	tree_method="hist", 
	num_round=1, 
	eta=1, 
	num_parallel_tree=200, 
	subsample=0.66, 
	sampling_method="uniform", 
	max_depth=10, 
	colsample_bynode=0.6, 
	min_split_loss=0, 
	min_child_weight=0, 
	max_leaves=100, 
	max_delta_step=Inf, 
	reg_alpha=0, 
	reg_lambda=0, 
	max_bin=256, 
	grow_policy="lossguide", 
	#max_cat_to_onehot=0, 
	nthread=2, 
	verbosity=1,
)

# ϵY ~ ϵT
resid_model_params = (
	booster="gblinear", 
	num_round=1, 
	eta=1, 
	reg_alpha=0, 
	reg_lambda=0, 
	nthread=2, 
	verbosity=2,
)

using XGBoost

# training set of 100 datapoints of 4 features
(X, y) = (randn(100,4), randn(100))

# create and train a gradient boosted tree model of 5 trees
bst = xgboost((X, y), num_round=5, max_depth=6, objective="reg:squarederror")

# obtain model predictions
ŷ = predict(bst, X)


using DataFrames
df = DataFrame(randn(100,3), [:a, :b, :y])

# can accept tabular data, will keep feature names
bst = xgboost((df[!, [:a, :b]], df.y))

# display importance statistics retaining feature names
importancereport(bst)

# return AbstractTrees.jl compatible tree objects describing the model
trees(bst)