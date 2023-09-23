import os, random, datetime 
import pandas as pd 


# create fake-data model for proof-of-concepts 
"""
a - 'advisor' mapping 
b - 'contract' transactions 
c - 'client' mapping 
d - 'date' mapping 
e - 'product' mapping 
f - exhaustive data mapping 
"""

# assumed to execute with dbt_portable/ as working directory 
dbt_seed_folder = "seed_data/"
if not os.path.exists(dbt_seed_folder):
    os.makedirs(dbt_seed_folder) 

n_a = 100
n_b = 1000 
n_c = 300 
n_d = 1096 
n_e = 7 


# a 
a_list = []
for a in range(n_a):
    a_record = {}
    a_record['a_id'] = f"a_{a}" 
    a_record['adv_id'] = random.randint(100001, 990000) 
    a_record['adv_name'] = f"Adv_{a}" 
    a_list.append(a_record)

a_data = pd.DataFrame(a_list)
a_data.head()


# c 
c_list = []
for c in range(n_c):
    c_record = {}
    c_record['c_id'] = f"c_{c}" 
    c_record['clt_id'] = f"C{random.randint(50001, 59999)}" 
    c_record['clt_name'] = f"Client_{c}" 
    c_list.append(c_record)

c_data = pd.DataFrame(c_list)
c_data.head()


# d 
d_list = []
for d in range(n_d):
    d_record = {}
    d_record['d_id'] = f"d_{d}" 
    d_record['cal_date'] = datetime.date(2020, 1, 1) + datetime.timedelta(d)
    d_record['week_day'] = datetime.date.weekday(d_record['cal_date']) 
    d_record['bus_day'] = 1 if 0 <= d_record['week_day'] <= 4 else 0
    d_list.append(d_record)

d_data = pd.DataFrame(d_list)
d_data.head(32) 


# e 
e_list = []
for e in range(n_e):
    e_record = {}
    e_record['e_id'] = f"e_{e}" 
    e_record['prod_id'] = f"p{(e+1) * 100}" 
    e_record['prod_name'] = f"Prod_{chr(65+e)}"
    e_list.append(e_record)

e_data = pd.DataFrame(e_list)
e_data.head()


# b 
b_list = []
for b in range(n_b):
    b_record = {}
    b_record['b_id'] = f"b_{b}" 
    b_record['cont_id'] = f"{chr(65 + random.randint(0, 5))}{random.randint(1111111,8888888)}" 
    b_record['cont_adv_id'] = a_data.adv_id[random.randint(0, n_a-1)]
    b_record['cont_own_id'] = c_data.clt_id[random.randint(0, n_c-1)]
    b_record['cont_prod_id'] = e_data.prod_id[random.randint(0, n_e-1)]
    b_record['cont_date'] = d_data.cal_date[random.randint(0, n_d-1)]
    b_record['cont_amt'] = 1000 * random.randint(100, 1000)
    b_list.append(b_record)

b_data = pd.DataFrame(b_list)
b_data.head()


# f 
f_data = pd.merge(b_data, a_data, 'left', left_on='cont_adv_id', right_on='adv_id')
f_data = pd.merge(f_data, c_data, 'left', left_on='cont_own_id', right_on='clt_id')
f_data = pd.merge(f_data, e_data, 'left', left_on='cont_prod_id', right_on='prod_id')
f_data = pd.merge(f_data, d_data, 'left', left_on='cont_date', right_on='cal_date')
f_data.head()


a_data.to_parquet(path=dbt_seed_folder+"a_advisor.parquet", engine='pyarrow', compression='zstd', index=False)
b_data.to_parquet(path=dbt_seed_folder+"b_contract.parquet", engine='pyarrow', compression='zstd', index=False)
c_data.to_parquet(path=dbt_seed_folder+"c_client.parquet", engine='pyarrow', compression='zstd', index=False)
d_data.to_parquet(path=dbt_seed_folder+"d_date.parquet", engine='pyarrow', compression='zstd', index=False)
e_data.to_parquet(path=dbt_seed_folder+"e_product.parquet", engine='pyarrow', compression='zstd', index=False)
f_data.to_parquet(path=dbt_seed_folder+"f_combined.parquet", engine='pyarrow', compression='zstd', index=False)



import duckdb as dd

queries = [
    "create schema portable.src;", 
    "create table src.a_advisor as from 'seed_data/a_advisor.parquet';", 
]

duck = dd.connect(database="__local_artifacts__/portable.duckdb")
for q in queries:
    dd.sql(query=q)

duck.close()

