# start persistent dagster-daemon process (mandatory for scheduled or queued run execution) 
cd 'S:/Datasets & Projects/LocalRepo/Sample-Projects/Analytics Infrastructure Sim/execution_model' 
$env:DAGSTER_HOME = 'S:/Datasets & Projects/LocalRepo/Sample-Projects/Analytics Infrastructure Sim/execution_model/deployed_instance' 

# as of dagster v1.1.11, 'dagster dev' runs both dagit and daemon
$dagster = 'S:/Python/Python_3_10/Scripts/dagster.exe' 
cls; .$dagster dev --python-file 'execution_patterns/ELT-graph.py' 
