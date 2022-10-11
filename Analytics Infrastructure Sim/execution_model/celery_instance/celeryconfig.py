import dagster as dag
import dagster_celery as cdag 

## Broker settings.
broker_url = 'amqp://guest:guest@localhost:5672//'

# List of modules to import when the Celery worker starts.
imports = ('myapp.tasks',)
worker_concurrency = 4 
worker_prefetch_multiplier = 2

## Using the database to store task state and results.
result_backend = 'db+sqlite:///results.db'


task_annotations = {
    'tasks.add': {'rate_limit': '1/s'}
    #, 'task_track_started': True
    #, 'task_time_limit': 600
    }

task_default_queue = 'celery' 
task_default_exchange = 'default' 
task_default_routing_key = 'default' 
task_queues = ( # queues to assign workers 
    cdag.Queue('celery', cdag.Exchange('default'), routing_key='default'),
    cdag.Queue('extract_queue', cdag.Exchange('extract'), routing_key='extract_pipeline'),
    cdag.Queue('loading_queue', cdag.Exchange('loading'), routing_key='loading_pipeline'),
    cdag.Queue('compute_queue', cdag.Exchange('compute'), routing_key='compute_pipeline'),
)

task_routes = { # assign tasks 
    'ext_a': {'queue': 'extract_queue', 'routing_key': 'extract_pipeline'},
    'lod_b': {'queue': 'loading_queue', 'routing_key': 'loading_pipeline'},
    'cpu_c': {'queue': 'compute_queue', 'routing_key': 'compute_pipeline'}
}