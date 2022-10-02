"""
$python = "C:\Users\tvand\Documents\Python\Python_3-9\python.exe"; cls; .$python
"""
import dagster as dag 
import asyncio 
from random import random, gauss


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
    return {'id':, 'n': n, 'extr': t}

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
        @dag.op(name=f'ext_{x}')
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
        dlog.debug(f'task {d['id']}: n={d['n']}, total={d['extr'] + d['load'] + d['cpu']}')
    return dag.Nothing

## Construct Dagster Graph of Ops
@dag.graph 
async def simple_workflow():
    (e, l, t) = op_factory()
    results = {}
    for i, d in enumerate(task_map.keys()): 
        results[d] = t[i]( 
                        l[i]( 
                            e[i]()
                        )
                    ) 
    task_report(results) 

@dag.repository
    def resources_repo():
        return [simple_workflow]
