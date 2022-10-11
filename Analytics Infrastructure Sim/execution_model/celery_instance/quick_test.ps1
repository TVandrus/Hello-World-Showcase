# shortcut to celery deployment:
# celery worker running on the same node as dagit
# celery worker in the same folder to access the Python job as dagit

# 1. 
# start task broker (RabbitMQ) 
cd 
docker run -p 5672:5672 rabbitmq:3.8.2


# 2. 
# start celery task workers 
cd 'S:/Datasets & Projects/LocalRepo/Sample-Projects/Analytics Infrastructure Sim/execution_model/celery_instance/' 

dagster-celery worker start --name extract_worker --queue extract_queue --config-yaml celeryconfig.yaml 
dagster-celery worker start --name load_worker --queue load_queue --config-yaml celeryconfig.yaml 
dagster-celery worker start --name transform_worker --queue transform_queue --config-yaml celeryconfig.yaml 

dagster-celery worker list 
#dagster-celery worker terminate --all 


# 3. 
# start persistent dagster-daemon process (mandatory for scheduled or queued run execution) 
cd 'S:/Datasets & Projects/LocalRepo/Sample-Projects/Analytics Infrastructure Sim/execution_model' 
$env:DAGSTER_HOME = 'S:/Datasets & Projects/LocalRepo/Sample-Projects/Analytics Infrastructure Sim/execution_model/celery_instance' 

$dagster_daemon = 'S:/Python/Python_3_10/Scripts/dagster-daemon.exe' 
cls; .$dagster_daemon run --python-file 'execution_patterns/ELT-graph.py' 


# 4. 
# start dagit server 
cd 'S:/Datasets & Projects/LocalRepo/Sample-Projects/Analytics Infrastructure Sim/execution_model' 
$env:DAGSTER_HOME = 'S:/Datasets & Projects/LocalRepo/Sample-Projects/Analytics Infrastructure Sim/execution_model/celery_instance' 

$dagit = 'S:/Python/Python_3_10/Scripts/dagit.exe' 
cls; .$dagit --python-file 'execution_patterns/ELT-graph.py' 
