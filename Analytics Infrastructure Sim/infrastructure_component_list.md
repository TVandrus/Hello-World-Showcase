# Shopping List aka Requirements 
Rev 0 - 2022 Q4 


## Database 
PostgreSQL 14 
pgAdmin 4 v6.14

## Pipeline Scripting 
Python
    v 3.11.1 
    # issue with Python 3.11 & dagster & grpcio
    pip install dagster dagit --find-links=https://github.com/dagster-io/build-grpcio/wiki/Wheels
    
    dagster dagster_postgres dagster_pandas dagit dagster_dbt dbt-core dbt-postgres

    pandas
    juliacall 

    import os 
    os.environ['PYTHON_JULIACALL_THREADS'] = '3'
    from juliacall import Main as jl
    jl.Threads.nthreads()




## Simulation/Analysis logic compute 
Julia
    v 1.8.4 
    DataFrames.jl v1.3.6 
    Pandas.jl v1.6.1
    LibPQ.jl v1.14.0
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
$julia = "S:/Julia/Julia-1.8.1/bin/julia.exe"; cls; .$julia; 
$dbt = "S:/Python/Python_3_10/Scripts/dbt.exe" 
$dagit = "S:/Python/Python_3_10/Scripts/dagit.exe" 
```