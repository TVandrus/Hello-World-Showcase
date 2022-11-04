# The celery CLI points to a module (via the -A argument)
# to find tasks. This file exists to be a target for that argument.
# Examples:
#   - See `worker_start_command` in dagster_celery.cli
#   - deployment-flower.yaml helm chart
from celery_instance.make_app_copy import make_app
from dagster_celery.tasks import create_task

import celery_instance.dagster_celery_config 

app = make_app()

execute_plan = create_task(app)
