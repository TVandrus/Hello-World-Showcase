"""
$python = "C:\Users\tvand\Documents\Python\Python_3-9\python.exe"; cls; .$python
"""
import dagster as dag 
import asyncio 
from random import random, gauss

## Define functions and configs

dlog = dag.get_dagster_logger()

n = 10 

for i in range(20):
    round(3 + max(gauss(mu=n, sigma=3), 0))


async def extract_task(n):
    t = round(3 + max(0, gauss(mu=n, sigma=3)))
    await asyncio.sleep(t)
    return {'n': n, 'extr': t}

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



## Construct Dagster Graph of Ops
