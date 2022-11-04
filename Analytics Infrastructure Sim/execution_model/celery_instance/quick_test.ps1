# shortcut to celery deployment:
# celery worker running on the same node as dagit
# celery worker in the same folder to access the Python job as dagit

# 1. 
# start task broker (RabbitMQ) 
Start-Process powershell -Verb runAs 
cd "S:\RabbitMQServer\rabbitmq_server-3.11.0\sbin"
.\rabbitmq-service.bat stop
.\rabbitmq-service.bat remove
$env:ERLANG_HOME = "S:\Erlang\Erlang OTP\erts-13.1.1"
$env:RABBITMQ_SERVICENAME = "RabbitMQ"
$env:RABBITMQ_BASE = "" # This is the location of log and database directories.
$env:RABBITMQ_NODENAME = "rabbit@localhost" # default
#Can be used to run multiple nodes on the same host.  Every node in a cluster must have a unique RABBITMQ_NODENAME
$env:RABBITMQ_NODE_PORT = 5672 # default
$env:ERLANG_SERVICE_MANAGER_PATH = "S:\Erlang\Erlang OTP\erts-13.1.1\bin"
$env:RABBITMQ_CONSOLE_LOG = "S:\RabbitMQServer\debug_logs"
.\rabbitmq-service.bat install
.\rabbitmq-service.bat start 


# 2. 
# start celery task workers 
cd 'S:/Datasets & Projects/LocalRepo/Sample-Projects/Analytics Infrastructure Sim/execution_model/'
$env:DAGSTER_HOME = 'S:/Datasets & Projects/LocalRepo/Sample-Projects/Analytics Infrastructure Sim/execution_model/celery_instance'


# unspecified queue
dagster-celery worker start -A celery_instance.app_copy --name default_worker --config-yaml celery_instance/celery_config.yaml 

# all queues
dagster-celery worker start -A celery_instance.app_copy --name multi_worker --queue dagster,extract_queue,loading_queue,compute_queue --config-yaml celery_instance/celery_config.yaml 

# task-specific queues
dagster-celery worker start -A celery_instance.app_copy --name extract_worker --queue extract_queue --config-yaml celery_instance/celery_config.yaml 
dagster-celery worker start -A celery_instance.app_copy --name loading_worker --queue loading_queue --config-yaml celery_instance/celery_config.yaml 
dagster-celery worker start -A celery_instance.app_copy --name compute_worker --queue compute_queue --config-yaml celery_instance/celery_config.yaml 


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
