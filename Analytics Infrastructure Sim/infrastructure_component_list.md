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
    v3.11.4 as of 2023-06
    python -m pip install --upgrade pip
    pip install --upgrade wheel
    pip list 

    pip install --upgrade "pandas[all]" pyarrow 
    pip install --upgrade scikit-learn xgboost shap juliacall 
    pip install --upgrade dagster dagit dagster-postgres dbt-postgres 

    import os 
    os.environ['PYTHON_JULIACALL_THREADS'] = '3'
    from juliacall import Main as jl
    jl.Threads.nthreads()


## Simulation/Analysis logic compute 
Julia
    v 1.9.2 as of 2023-07

    Pluto v0.19.27
    PlutoUI v0.7.52
    DataFrames v1.6.1
    CSV v0.10.11
    Parquet v0.8.4
    ShapML v0.3.2
    XGBoost v2.3.1

    PyCall v1.96.1
    ENV["PYTHON"] = ".../Python/Python_311/python.exe"


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