
cd 'S:/Datasets & Projects/LocalRepo/Sample-Projects/Analytics Infrastructure Sim/execution_model' 
$env:DAGSTER_HOME = 'S:/Datasets & Projects/LocalRepo/Sample-Projects/Analytics Infrastructure Sim/execution_model/deployed_instance' 
$dagit = 'S:/Python/Python_3_10/Scripts/dagit.exe' 
cls; .$dagit --python-file 'execution_patterns/ELT-graph.py' 
