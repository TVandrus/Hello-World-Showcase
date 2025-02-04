# Shopping List aka Requirements 
Rev 0 - 2022 Q4 
Rev 1 - 2023 Q1


## Database 
PostgreSQL 15.2
    DB name = development_db 
    superuser = postgres:postgres 
    general user role = dev_user: dev_user
    dagster logging role = dag_log: dag_log
pgAdmin 4 v6.21

## Pipeline Scripting 
Python
    v3.10.10 as of 2023-03

    $python = "S:/Python/Python_3_10/python.exe"; cls; .$python; 
    .$python -m pip install --upgrade pip

    $pip = "S:/Python/Python_3_10/Scripts/pip.exe" 
    .$pip list 

    .$pip install --upgrade wheel
    .$pip install --upgrade dagster dagit dagster-postgres dbt-core dbt-postgres --find-links=https://github.com/dagster-io/build-grpcio/wiki/Wheels # issue with Python 3.11 & dagster & grpcio - 2023-03
    .$pip install --upgrade SQLAlchemy  pyarrow fastparquet parquet pandas pyspark
    .$pip install --upgrade scikit-learn xgboost juliacall 

    import os 
    os.environ['PYTHON_JULIACALL_THREADS'] = '3'
    from juliacall import Main as jl
    jl.Threads.nthreads()


## Simulation/Analysis logic compute 
Julia
    v 1.8.4 
    CSV
    DataFrames.jl v1.3.6 
    Pandas.jl v1.6.1
    Parquet.jl
    Pluto.jl v0.19.12 

    PyCall.jl
    ENV["PYTHON"] = "S:/Python/Python_3_10/python.exe"


# Reference Docs
https://www.postgresql.org/docs/current/index.html 
https://docs.julialang.org/en/v1/ 
https://docs.python.org/3/ 
https://docs.dagster.io/deployment/overview 
https://docs.getdbt.com/reference/dbt_project.yml


# PowerShell Shortcuts

```powershell
$pip = "S:/Python/Python_3_10/Scripts/pip.exe" 
$python = "S:/Python/Python_3_10/python.exe"; cls; .$python; 
$julia = "S:/Julia/Julia-1.8.5/bin/julia.exe"; cls; .$julia; 
$dbt = "S:/Python/Python_3_10/Scripts/dbt.exe" 
$dagit = "S:/Python/Python_3_10/Scripts/dagit.exe" 
```