"""
"""
import dagster as dag 
import dagster_celery as cdag 
import asyncio 
from random import random, gauss
import typing as tp 


## Define functions and configs

dlog = dag.get_dagster_logger()
n_default = 10 

task_map = {
    'a': 10,
    'b': 12, 
    'c': 16,
    'd': 22,
    'e': 30
}

async def extract_task(id, n=n_default):
    t = round(3 + max(0, gauss(mu=n, sigma=3)))
    await asyncio.sleep(t)
    return {'id': id, 'n': n, 'extr': t}

async def load_task(tlog):
    t = round(1 + tlog['extr'] * (0.75 + 0.3*random()))
    await asyncio.sleep(t)
    tlog['load'] = t
    return tlog

async def compute_task(tlog):
    t = round(5 + tlog['n'] * max(0.5, gauss(mu=1, sigma=1)))
    await asyncio.sleep(t)
    tlog['cpu'] = t
    return tlog


## Define Dagster Ops
def op_factory():
    e_list = [] 
    l_list = [] 
    t_list = [] 
    for x in task_map.keys():
        @dag.op(name=f'ext_{x}')
        async def ext():
            dlog.info(f'start ext_{x}, n={task_map[x]}')
            task_log = await extract_task(id=x, n=task_map[x])
            dlog.info(f'finished ext_{x}')
            return task_log
        e_list.append(ext)
    
    for x in task_map.keys():
        @dag.op(name=f'load_{x}')
        async def ld(prev):
            dlog.info(f'start load_{x}')
            task_log = await load_task(prev)
            dlog.info(f'finished load_{x}')
            return task_log
        l_list.append(ld)
    
    for x in task_map.keys():
        @dag.op(name=f'cpu_{x}')
        async def comp(prev):
            dlog.info(f'start cpu_{x}')
            task_log = await compute_task(prev)
            dlog.info(f'finished cpu_{x}')
            return task_log
        t_list.append(comp)

    return e_list, l_list, t_list

@dag.op
def task_report(deps): 
    for d in deps:
        dlog.debug(f"task {d['id']}: n={d['n']}, total={d['extr'] + d['load'] + d['cpu']}")
    return dag.Nothing


# custom ops
n_custom = 15

@dag.op
async def ext(context: dag.OpExecutionContext):
    id = context.op_handle
    n=n_custom
    dlog.info(f"start {id}")
    t = round(3 + max(0, gauss(mu=n, sigma=3)))
    await asyncio.sleep(t)
    dlog.info(f"finished {id}")
    return dag.Nothing

@dag.op
async def ld(context: dag.OpExecutionContext, dep: tp.List):
    id = context.op_handle
    n=n_custom
    dlog.info(f"start {id}")
    t = round(1 + n * (0.75 + 0.5*random()))
    await asyncio.sleep(t)
    dlog.info(f"finished {id}")
    return dag.Nothing

@dag.op
async def comp(context: dag.OpExecutionContext, dep: tp.List):
    id = context.op_handle
    n=n_custom
    dlog.info(f"start {id}")
    t = round(5 + n * max(0.5, gauss(mu=1, sigma=1)))
    await asyncio.sleep(t)
    dlog.info(f"finished {id}")
    return dag.Nothing


## Construct Dagster Graph of Ops
@dag.graph 
def simple_workflow():
    (e, l, t) = op_factory()
    results = []
    for i, d in enumerate(task_map.keys()): 
        results.append(t[i](l[i](e[i]() ) ) )
    task_report(results) 


@dag.graph
def custom_workflow():
    compile = comp.alias('cpu_a')([])
    setup = [
        ext.alias('ext_b')(), 
        ext.alias('ext_c')(), 
        ext.alias('ext_d')(), 
        comp.alias('cpu_h')([ext.alias('ext_e')()])     
    ]
    preload = ld.alias('load_k')(setup)
    proj_load = ld.alias('load_l')([ext.alias('ext_f')(), preload])
    initialise = ld.alias('load_p')([compile, proj_load])
    transform = comp.alias('cpu_q')([initialise])
    model_load = comp.alias('cpu_o')(
                [ld.alias('load_m')(
                    [comp.alias('cpu_j')(
                        [ld.alias('load_i')(
                            [ext.alias('ext_g')()] 
                        )] 
                    )] 
                )] 
            )
    report = comp.alias('cpu_r')([initialise, model_load])


@dag.repository
def resources_repo():
    simple_job = simple_workflow.to_job(name='simple_job', config={"execution": {"config":{"multiprocess": {"max_concurrent": 2}}}}) 
    simple_job_celery = simple_workflow.to_job(name='simple_job_celery', executor_def=cdag.celery_executor) 
    custom_job = custom_workflow.to_job(name='custom_job', config={"execution": {"config":{"multiprocess": {"max_concurrent": 3}}}}) 
    custom_job_serial = custom_workflow.to_job(name='custom_job_serial', executor_def=dag.in_process_executor) 

    return [simple_job
        #, simple_job_celery
        , custom_job 
        , custom_job_serial
    ]
