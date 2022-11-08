import kombu 
import datetime as dt 

## Broker settings.
broker_url = 'amqp://guest:guest@localhost:5672//' 

## Using the database to store task state and results.
backend = 'rpc://' 
result_backend = 'rpc://' 
#result_backend = 'db+postgresql://dev_user:dev_user@localhost:5432/development_db' 
result_backend_always_retry = True
result_backend_base_sleep_between_retries_ms = 1000
result_backend_max_retries = 10
result_cache_max = 100 
result_extended = True
result_expires = dt.timedelta(hours=12)

# List of modules to import when the Celery worker starts.
include = ['execution_patterns.ELT-graph']

broker_pool_limit = 10 
broker_connection_timeout = 10 

event_exchange = 'celeryev' # experimental, keep default
event_queue_ttl = 30
event_queue_expires = 300 
event_queue_prefix = 'celery_events'
control_exchange = 'celery' # experimental, keep default
control_queue_ttl = 30
control_queue_expires = 300

worker_send_task_events = True 
worker_redirect_stdouts = 'DEBUG'
worker_lost_wait = 10
worker_proc_alive_timeout = 10
worker_cancel_long_running_tasks_on_connection_loss = True 
worker_concurrency = 2 # worker sub-processes
worker_prefetch_multiplier = 1 # how many additional batches of tasks to claim


task_send_sent_event = True 
task_always_eager = False # simulates by running in local process, not on worker
task_ignore_result = False 
task_track_started = True
task_time_limit = 600
task_default_rate_limit = '1/s'

#task_exchange_def = kombu.Exchange(name='tasks', type='topic', durable=False, auto_delete=True) 
task_exchange_def = 'dagster'

task_create_missing_queues = False 
task_default_queue = 'dagster' 
task_default_exchange = task_default_queue 
#task_default_exchange_type = 'direct' # direct for exact key match, topic for pattern partial key matching
task_default_routing_key = task_default_queue 
task_default_priority = 1 
task_queue_max_priority = 10 
task_queues = ( # queues to assign workers 
    kombu.Queue(name='dagster', routing_key='dagster.execute_plan'), 
    kombu.Queue(name='extract_queue', routing_key='extract_queue.execute_plan'), 
    kombu.Queue(name='loading_queue', routing_key='loading_queue.execute_plan'), 
    kombu.Queue(name='compute_queue', routing_key='compute_queue.execute_plan'), 
)
task_routes = { 
    'dagster.execute_plan': {'queue': 'dagster', 'routing_key': 'dagster.execute_plan'},
    'dagster.#': {'queue': 'dagster' },
    'extract_queue.#': {'queue': 'extract_queue'},
} 

