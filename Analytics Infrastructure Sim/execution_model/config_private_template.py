# config_private.py 

local_proj_dir = 'S:/.../Sample-Projects/Analytics Infrastructure Sim/' 

# infrastructure 
python_exe = 'S:/.../python.exe' 
pip_exe = 'S:/.../Scripts/pip.exe' 

pg_host = 'localhost' 
pg_port = '5432' 
pg_user = 'user' 
pg_pass = 'userpass' 
pg_dbname = 'db_name' 


# data model 
dbt_proj_dir = local_proj_dir + 'data_model/' 
dbt_exe = 'S:/.../Scripts/dbt.exe' 
dbt_profiles = 'C:/Users/.../.dbt/profiles.yml' 

# execution model 
dag_proj_dir = local_proj_dir + 'execution_model/' 
dag_inst_default = dag_proj_dir + 'deployed_instance/' 
dagster_daemon = 'S:/.../Scripts/dagster-daemon.exe' 
dagit = 'S:/.../Scripts/dagit.exe' 

# simulation modules
julia_exe = 'S:/.../julia.exe' 
sim_proj_dir = local_proj_dir + 'simulation_modules/' 
