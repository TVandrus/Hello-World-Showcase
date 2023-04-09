import pandas as pd 
import sqlalchemy 
import os 


# cache in partitioned ZSTD Parquet for fast OLAP-style access (selective bulk decompress and complex query)


# cache in Postgres for parallel queries; multiple defined transformations and views w dbt 
os.chdir("Analytics Infrastructure Sim/simulation_modules/")
pg_engine = sqlalchemy.engine.URL(
    drivername='postgresql+psycopg2',
    host='localhost',
    port=5432,
    database='development_db', 
    username='dev_user', password='dev_user', # Don't do this 

)

sqlalchemy.create_engine("postgresql+psycopg2://dev_user:dev_user@localhost/development_db", use_insertmanyvalues=False)
test = pg_engine.connect()
test.close()

for f in os.listdir("run_setup/ux_input/"):
    table_name = f.split(sep=".")[0] 
    df = pd.read_parquet(path="run_setup/ux_input/"+f) 
    df.to_sql(name=table_name, schema="ux_input", con=pg_engine, if_exists='append', index=False)


for f in os.listdir("run_simulation/ux_stage/"):
    table_name = f.split(sep=".")[0] 
    df = pd.read_parquet(path="run_simulation/ux_stage/"+f) 
    print(f"{table_name} - {df.dtypes}")
    df.to_sql(name=table_name, schema="ux_stage", con=pg_engine, if_exists='append', index=False, chunksize=100_000)



# cache as Arrow in-memory for maximum performance on complex operations 


# cache as DuckDB/SQLite for compromise of all above 

