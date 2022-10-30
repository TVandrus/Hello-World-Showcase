import dagster_celery as cdag 
import kombu 
import os 

## Broker settings.
broker_url = 'amqp://guest:guest@localhost:5672//'
#broker_url = "pyamqp://guest@{hostname}:5672//".format(hostname=os.getenv("DAGSTER_CELERY_BROKER_HOST", "localhost"))

# List of modules to import when the Celery worker starts.
imports = ('dagster_celery.tasks','./execution')
worker_concurrency = 4 
worker_prefetch_multiplier = 2

## Using the database to store task state and results.
result_backend = 'db+sqlite:///results.db'
#result_backend = 'rpc://'

task_annotations = {
    'tasks.add': {'rate_limit': '1/s'}
    #, 'task_track_started': True
    #, 'task_time_limit': 600
    }

task_default_queue = 'celery' 
task_default_exchange = 'default' 
task_default_routing_key = 'default' 
task_queues = ( # queues to assign workers 
    kombu.Queue('celery', kombu.Exchange('default'), routing_key='default'),
    kombu.Queue('extract_queue', kombu.Exchange('extract'), routing_key='extract_pipeline'),
    kombu.Queue('loading_queue', kombu.Exchange('loading'), routing_key='loading_pipeline'),
    kombu.Queue('compute_queue', kombu.Exchange('compute'), routing_key='compute_pipeline'),
)

task_routes = { # assign tasks 
    'ext_a': {'queue': 'extract_queue', 'routing_key': 'extract_pipeline'},
    'lod_b': {'queue': 'loading_queue', 'routing_key': 'loading_pipeline'},
    'cpu_c': {'queue': 'compute_queue', 'routing_key': 'compute_pipeline'}
}

broker_transport_options = {
    # these defaults were lifted from examples - worth updating after some experience
    "max_retries": 1,
    #"interval_start": 0,
    #"interval_step": 0.2,
    #"interval_max": 0.5,
}
