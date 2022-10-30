
# The celery CLI points to a module (via the -A argument)
# to find tasks. This file exists to be a target for that argument.
# Examples:
#   - See `worker_start_command` in dagster_celery.cli
#   - deployment-flower.yaml helm chart
from celery import Celery
from celery.utils.collections import force_mapping
from dagster_celery.tasks import create_task


import dagster_celery_config as dcconfig

def make_app_with_task_routes(config_module):
    app_ = Celery("dagster")

    obj = force_mapping(app_.loader._smart_import(config_module))
    app_.conf.update(obj)
    app_.loader.import_module("celery.contrib.testing.tasks")

    app_.conf.task_queues = config_module.task_queues 
    app_.conf.task_routes = config_module.task_routes
    #app_.conf.task_queue_max_priority = 10
    #app_.conf.task_default_priority = 5
    return app_

app = make_app_with_task_routes(config_module=dcconfig) 
execute_plan = create_task(app)
