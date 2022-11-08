from celery import Celery
from celery.utils.collections import force_mapping
from kombu import Queue

from dagster._seven import is_module_available


def make_app(app_args=None):
    return make_app_with_task_routes(
        app_args=app_args,
        task_routes={"execute_plan": {"queue": "dagster", "routing_key": "dagster.execute_plan"}},
    )


def make_app_with_task_routes(task_routes=None, app_args=None):
    app_ = Celery("dagster_celery_app_copy", **(app_args if app_args else {}))

    if app_args is None:
        app_.config_from_object("celery_instance.dagster_celery_config", force=True)

        if is_module_available("dagster_celery_config"):
            obj = force_mapping(app_.loader._smart_import("dagster_celery_config"))
            app_.conf.update(obj)

    #app_.loader.import_module("celery.contrib.testing.tasks")

    # hardcoded overrides if config value will be blank or inappropriate 
    #app_.conf.task_queues = [Queue("dagster", routing_key="dagster.#")]
    if task_routes:
        app_.conf.task_routes = task_routes
    #app_.conf.task_queue_max_priority = 10
    #app_.conf.task_default_priority = 5
    return app_
