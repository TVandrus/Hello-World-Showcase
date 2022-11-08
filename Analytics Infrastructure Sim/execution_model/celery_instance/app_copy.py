# The celery CLI points to a module (via the -A argument)
# to find tasks. This file exists to be a target for that argument.
# Examples:
#   - See `worker_start_command` in dagster_celery.cli
#   - deployment-flower.yaml helm chart
from celery_instance.make_app_copy import make_app, make_app_with_task_routes 
from celery_instance.tasks_copy import create_task

app = make_app_with_task_routes()

execute_plan = create_task(app)
