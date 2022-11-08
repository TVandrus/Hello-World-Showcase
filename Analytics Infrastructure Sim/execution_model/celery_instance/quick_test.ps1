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
    $env:RABBITMQ_BASE = "S:\RabbitMQServer\logs" # This is the location of log and database directories.
    $env:RABBITMQ_NODENAME = "rabbit@localhost" # default
    #Can be used to run multiple nodes on the same host.  Every node in a cluster must have a unique RABBITMQ_NODENAME
    $env:RABBITMQ_NODE_PORT = 5672 # default
    $env:ERLANG_SERVICE_MANAGER_PATH = "S:\Erlang\Erlang OTP\erts-13.1.1\bin"
    $env:RABBITMQ_CONSOLE_LOG = "S:\RabbitMQServer\debug_logs"
    .\rabbitmq-service.bat install
    .\rabbitmq-service.bat start 

    # diagnostics
    # rabbitmqctl [--node <node>] [--timeout <timeout>] [--longnames] [--quiet] <command> [<command options>] 
    $rabbitmq = "S:\RabbitMQServer\rabbitmq_server-3.11.0\sbin\rabbitmqctl.bat"
    "S:\RabbitMQServer\rabbitmq_server-3.11.0\sbin\rabbitmq-defaults.bat"
    $rabbitmq_plugins = "S:\RabbitMQServer\rabbitmq_server-3.11.0\sbin\rabbitmq-plugins.bat"
    "S:\RabbitMQServer\rabbitmq_server-3.11.0\sbin\rabbitmq-diagnostics.bat"
    "S:\RabbitMQServer\rabbitmq_server-3.11.0\sbin\rabbitmq-queues.bat"
    "S:\RabbitMQServer\rabbitmq_server-3.11.0\sbin\rabbitmq-server.bat"


    cls; .$rabbitmq ping; .$rabbitmq status; 
    cls; .$rabbitmq list_exchanges; "`n`n"; .$rabbitmq list_queues; 

    cls; .$rabbitmq list_exchanges; "`n`n"; .$rabbitmq list_queues; "`n`n"; .$rabbitmq list_consumers; 
    cls; .$rabbitmq stop_app; .$rabbitmq reset; .$rabbitmq start_app; 

    .$rabbitmq list_global_parameters
    .$rabbitmq list_parameters
    .$rabbitmq set_parameter
    .$rabbitmq set_cluster_name
    .$rabbitmq environment

    .$rabbitmq_plugins enable rabbitmq_event_exchange

# 2. 
# start celery task workers 
    cd 'S:/Datasets & Projects/LocalRepo/Sample-Projects/Analytics Infrastructure Sim/execution_model/'
    $env:DAGSTER_HOME = 'S:/Datasets & Projects/LocalRepo/Sample-Projects/Analytics Infrastructure Sim/execution_model/celery_instance'

    # unspecified queue
    cls; dagster-celery worker start -A celery_instance.app_copy --name default_worker --config-yaml celery_instance/celery_config.yaml --loglevel=INFO

    # all queues
    cls; dagster-celery worker start -A celery_instance.app_copy --name multi_worker --queue dagster,extract,loading,compute --config-yaml celery_instance/celery_config.yaml --loglevel=INFO

    # task-specific queues
    cls; dagster-celery worker start -A celery_instance.app_copy --name extract_worker --queue extract_queue --config-yaml celery_instance/celery_config.yaml 
    cls; dagster-celery worker start -A celery_instance.app_copy --name loading_worker --queue loading_queue --config-yaml celery_instance/celery_config.yaml 
    cls; dagster-celery worker start -A celery_instance.app_copy --name compute_worker --queue compute_queue --config-yaml celery_instance/celery_config.yaml 

    dagster-celery worker list 
    cls; dagster-celery status -A celery_instance.app_copy --config-yaml celery_instance/celery_config.yaml 
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

 
# start celery monitoring via Flower
    cd 'S:/Datasets & Projects/LocalRepo/Sample-Projects/Analytics Infrastructure Sim/execution_model/'
    $env:DAGSTER_HOME = 'S:/Datasets & Projects/LocalRepo/Sample-Projects/Analytics Infrastructure Sim/execution_model/celery_instance'
    celery -A celery_instance.app_copy flower 
    
    http://localhost:5555

