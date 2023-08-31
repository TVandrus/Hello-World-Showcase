# dbt_portable

Goal: 
- implement a streamlined, portable data-transformation workflow with minimal dependencies for quick ad-hoc setup
- but also maximum flexibility/scalability (scale for performance and complexity/organizational demands)
- dbt_portable is a functioning demonstration of this workflow

## Design

### DuckDB

https://duckdb.org

- the spirit of SQLite: portable/in-process, minimal setup, minimal dependencies
- implementation that enables easy performance on analytical workloads
- compatible interface for Parquet and Arrow/Feather formats (fits into modern analytics tech stack) 
https://duckdb.org/docs/archive/0.8.1/

### dbt on DuckDB
https://docs.getdbt.com/docs/core/connect-data-platform/duckdb-setup


### dbt Resources:
- Learn more about dbt [in the docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](https://community.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices

# Workflow Demo

The assumption is that one has downloaded the entire contents of dbt_portable and opened it as their working directory, and has a valid Python installation in their environment. The shell code assumes a Windows environment, with Python.exe and Python/Scripts/ available on the local PATH.
Having DBeaver or your database IDE of choice is also recommended for easier viewing, but not strictly necessary.

```shell 
pip install dbt-duckdb 
pip show dbt-duckdb # requires dbt-core and duckdb
pip show duckdb # no external dependencies!
```

## Generate data
 This demo comes with its own data ... some assembly required.

 ```shell
 python "fake_data_simulation.py" # does require some basic Python packages 
 ``` 

This should populate dbt_portable/seed_data/ with some CSV files representing fake data extracts, matching the list documented in seed.yml

```shell
dbt debug # confirms connection to DuckDB target as specified in dbt profiles.yml
dbt compile # check for dbt configuration errors 
dbt seed # load seed files into DuckDB
dbt build # executes all dbt nodes, materializing them in DuckDB 
dbt docs generate # compiles template and any user-contributed doc strings for dbt's underlying Directed Acyclic Graph of nodes 
dbt docs serve # open the auto-generated documentation in a web browser
```

Now you can also open your DB IDE, and view your active and functional SQL database.
Note: DuckDB only supports one open connection at a time; dbt will not execute Seeds/Models while another application has an open DuckDB connection
