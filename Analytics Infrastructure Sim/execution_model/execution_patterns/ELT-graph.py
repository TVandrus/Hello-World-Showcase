"""
"""
import dagster as dag 
from celery_instance.executor_copy import celery_executor 
from random import random, gauss
import typing as tp 
import asyncio, os, yaml  
from pathlib import Path

## Define functions and configs

dlog = dag.get_dagster_logger()
n_default = 10 

task_map = {
    'a': 10,
    'b': 12, 
    'c': 16,
    'd': 22,
    'e': 30,
}

source_map = {
    'A': {'n': 20, 'latency': 2}, 
    'B': {'n': 25, 'latency': 2}, 
    'C': {'n': 30, 'latency': 1}, 
    'D': {'n': 40, 'latency': 1}, 
    #'E': {'n': 50, 'latency': 0}, 
}

async def extract_det(id, q, map):
    async with q:
        dur = map[id]['n'] / 4 + map[id]['latency'] 
        await asyncio.sleep(dur)
    return dur 

async def loading_det(id, q, map):
    async with q:
        dur = map[id]['n'] / 2 
        await asyncio.sleep(dur)
    return dur 

async def compute_det(id, q, map):
    async with q: 
        dur = (map[id]['n'] / 8) ** 2 + 1
        await asyncio.sleep(dur)
    return dur 


def det_op_factory():
    op_map = source_map
    e_list = [] 
    l_list = [] 
    t_list = [] 
    queues = {
        'extract': asyncio.Semaphore(1), 
        'loading': asyncio.Semaphore(1), 
        'compute': asyncio.Semaphore(1), 
    }
    for x in op_map.keys():
        @dag.op(name=f'd_ext_{x}', ins={'n': dag.In(op_map[x]['n'])})
        async def ext():
            dlog.info(f"start ext_{x}, n={op_map[x]['n']}")
            task_log = await extract_det(id=x, q=queues['extract'], map=op_map)
            dlog.info(f'finished ext_{x}')
            return task_log
        fn = ext 
        e_list.append(fn)
    
    for x in op_map.keys():
        @dag.op(name=f'd_load_{x}')
        async def ld(dep):
            dlog.info(f'start load_{x}')
            task_log = await loading_det(id=x, q=queues['loading'], map=op_map)
            dlog.info(f'finished load_{x}')
            return dep + task_log
        fn = ld
        l_list.append(fn)
    
    for x in op_map.keys():
        @dag.op(name=f'd_cpu_{x}')
        async def comp(dep):
            dlog.info(f'start cpu_{x}')
            task_log = await compute_det(id=x, q=queues['compute'], map=op_map)
            dlog.info(f'finished cpu_{x}')
            return {x: dep + task_log}
        fn = comp
        t_list.append(fn)

    return e_list, l_list, t_list, queues


@dag.op
def display(dep):
    dlog.info(dep)

@dag.graph()
def det_dispatcher():
    e, l, t, q = det_op_factory()
    results = []
    for i in range(len(e)):
        results.append(t[i](l[i](e[i]())))
    display(results)


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
def simple_op_factory():
    e_list = [] 
    l_list = [] 
    t_list = [] 
    for x in task_map.keys():
        
        @dag.op(name=f'ext_{x}', tags={'dagster-celery/queue': 'extract_queue'})
        async def ext():
            dlog.info(f'start ext_{x}, n={task_map[x]}')
            task_log = await extract_task(id=x, n=task_map[x])
            dlog.info(f'finished ext_{x}')
            return task_log
        fn = ext 
        e_list.append(fn)
    
    for x in task_map.keys():
        @dag.op(name=f'load_{x}', tags={'dagster-celery/queue': 'loading_queue'})
        async def ld(prev):
            dlog.info(f'start load_{x}')
            task_log = await load_task(prev)
            dlog.info(f'finished load_{x}')
            return task_log
        fn = ld
        l_list.append(fn)
    
    for x in task_map.keys():
        @dag.op(name=f'cpu_{x}', tags={'dagster-celery/queue': 'compute_queue'})
        async def comp(prev):
            dlog.info(f'start cpu_{x}')
            task_log = await compute_task(prev)
            dlog.info(f'finished cpu_{x}')
            return task_log
        fn = comp
        t_list.append(fn)

    return e_list, l_list, t_list

@dag.op
def task_report(deps): 
    for d in deps:
        dlog.debug(f"task {d['id']}: n={d['n']}, total={d['extr'] + d['load'] + d['cpu']}")
    return dag.Nothing


# custom ops base
n_custom = 15

@dag.op(tags={'dagster-celery/queue': 'extract_queue'})
async def ext(context: dag.OpExecutionContext):
    '''
    Expected: (5 + n) seconds per extraction op
    '''
    id = context.op_handle
    n=n_custom
    dlog.info(f"start {id}")
    t = round(5 + max(0, gauss(mu=n, sigma=3)))
    await asyncio.sleep(t)
    dlog.info(f"finished {id}")
    return dag.Nothing

@dag.op(tags={'dagster-celery/queue': 'loading_queue'})
async def ld(context: dag.OpExecutionContext, dep: tp.List):
    '''
    Expected: (3 + 0.85*n * num_input_elements) 
    '''
    id = context.op_handle
    n=n_custom * len(dep) 
    dlog.info(f"start {id}")
    t = round(3 + n * (0.6 + 0.5*random()))
    await asyncio.sleep(t)
    dlog.info(f"finished {id}")
    return dag.Nothing

@dag.op(tags={'dagster-celery/queue': 'compute_queue'})
async def comp(context: dag.OpExecutionContext, dep: tp.List):
    '''
    Expected: (1 + 1.5*n) seconds per compute op
    '''
    id = context.op_handle
    n=n_custom
    dlog.info(f"start {id}")
    t = round(1 + n * max(0.7, gauss(mu=1.5, sigma=1)))
    await asyncio.sleep(t)
    dlog.info(f"finished {id}")
    return dag.Nothing



## Construct Dagster Graph of Ops
@dag.graph 
def simple_workflow():
    (e, l, t) = simple_op_factory()
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



@dag.graph
def ELT_pipeline_workflow():
    '''
    Simulated Extract-Transform-Load pipeline workflow
    (14 extract * ())
    '''
    landing_data = ld.alias('loading_landing')(
        [ ext.alias('extract_sales_mapping')(), 
        ext.alias('extract_sales_actuals')(), 
        ext.alias('extract_sales_sharepoint')(), 
        ext.alias('extract_sales_lan')(), 
        ext.alias('extract_sales_queries')() 
        ]) 
    run_compile = comp.alias('compute_init')([landing_data]) 
    run_docs = comp.alias('compute_docs')([run_compile]) 
    seed_data = ld.alias('loading_seeds')(
        [comp.alias('compute_encode')(
            [ ext.alias('extract_seed_product')(), 
            ext.alias('extract_seed_dates')(), 
            ext.alias('extract_seed_agents')(), 
            ext.alias('extract_seed_codes')()
            ]) 
        ])
    non_sales_data = ld.alias('loading_peripheral')(
        [ ext.alias('extract_src_appuser')(), 
        ext.alias('extract_src_clientx')(), 
        ext.alias('extract_src_pilot_monitor')(), 
        ext.alias('extract_src_pilot_target')(), 
        run_compile, 
        seed_data 
        ]) 
    projections = ld.alias('loading_proj_pre')( 
        [ comp.alias('compute_proj')( 
            [ ld.alias('loading_proj')( 
                [ ext.alias('extract_proj_config')(), 
                run_compile, 
                seed_data
                ])
            ])
        ])
    main_build = comp.alias('compute_build')([projections, non_sales_data]) 
    exports = comp.alias('compute_export')([main_build]) 
    check_logs = comp.alias('compute_logs')([main_build]) 


@dag.repository
def resources_repo():
    simple_job = simple_workflow.to_job(name='simple_job', config={"execution": {"config":{"multiprocess": {"max_concurrent": 2}}}}) 
    simple_celery = simple_workflow.to_job(
        name='simple_job_celery', 
        executor_def=celery_executor,
        config=yaml.safe_load(Path('celery_instance/celery_config.yaml').read_text())
    ) 
    custom_job = custom_workflow.to_job(name='custom_job', config={"execution": {"config":{"multiprocess": {"max_concurrent": 3}}}}) 
    custom_serial = custom_workflow.to_job(name='custom_job_serial', executor_def=dag.in_process_executor) 
    ELT_job = ELT_pipeline_workflow.to_job(name='ELT_pipeline_job', config={"execution": {"config":{"multiprocess": {"max_concurrent": 4}}}})
    ELT_serial = ELT_pipeline_workflow.to_job(name='ELT_pipeline_job_serial', executor_def=dag.in_process_executor)
    ELT_celery = ELT_pipeline_workflow.to_job(
        name='ELT_pipeline_job_celery', 
        executor_def=celery_executor, 
        config=yaml.safe_load(Path('celery_instance/celery_config.yaml').read_text())
    )

    return [#simple_workflow 
        #, simple_job 
        #simple_celery 
         det_dispatcher
        , custom_workflow 
        , custom_job 
        , custom_serial 
        , ELT_pipeline_workflow 
        , ELT_job 
        , ELT_serial 
        , ELT_celery 
    ]
