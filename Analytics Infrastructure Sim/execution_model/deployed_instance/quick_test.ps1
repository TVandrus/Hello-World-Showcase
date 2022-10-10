# start persistent dagster-daemon process (mandatory for scheduled or queued run execution) 
cd 'S:/Datasets & Projects/LocalRepo/Sample-Projects/Analytics Infrastructure Sim/execution_model' 
$env:DAGSTER_HOME = 'S:/Datasets & Projects/LocalRepo/Sample-Projects/Analytics Infrastructure Sim/execution_model/deployed_instance' 

$dagster_daemon = 'S:/Python/Python_3_10/Scripts/dagster-daemon.exe' 
cls; .$dagster_daemon run --python-file 'execution_patterns/ELT-graph.py' 

# start dagit server 
cd 'S:/Datasets & Projects/LocalRepo/Sample-Projects/Analytics Infrastructure Sim/execution_model' 
$env:DAGSTER_HOME = 'S:/Datasets & Projects/LocalRepo/Sample-Projects/Analytics Infrastructure Sim/execution_model/deployed_instance' 

$dagit = 'S:/Python/Python_3_10/Scripts/dagit.exe' 
cls; .$dagit --python-file 'execution_patterns/ELT-graph.py' 
