import kombu 

## Broker settings.
broker_url = 'pyamqp://guest:guest@localhost//' 
#broker_url = "pyamqp://guest@{hostname}:5672//".format(hostname=os.getenv("DAGSTER_CELERY_BROKER_HOST", "localhost"))
## Using the database to store task state and results.
backend = 'rpc://' 
result_backend = backend 

# List of modules to import when the Celery worker starts.
include = ['execution_patterns.ELT-graph']

broker_pool_limit = 10 
broker_connection_timeout = 10 
broker_transport_options = { 
    "max_retries": 2, 
    "interval_start": 0, 
    "interval_step": 0.5, 
    "interval_max": 1.0, 
}

worker_send_task_events = False 
worker_concurrency = 4 
worker_prefetch_multiplier = 2 

task_create_missing_queues = True 
task_default_queue = 'dagster' 
task_default_exchange = 'default' 
task_default_routing_key = 'default_route' 
task_default_priority = 5 
task_queue_max_priority = 10 
task_always_eager = False 
task_queues = ( # queues to assign workers 
    kombu.Queue('dagster_celery_queue', kombu.Exchange('default'), routing_key='default_route'),
    kombu.Queue('extract_queue', kombu.Exchange('extract'), routing_key='extract_pipeline'),
    kombu.Queue('loading_queue', kombu.Exchange('loading'), routing_key='loading_pipeline'),
    kombu.Queue('compute_queue', kombu.Exchange('compute'), routing_key='compute_pipeline'),
)
