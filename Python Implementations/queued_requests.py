import asyncio
import logging, sys
from random import random as urand
import time, math 

logger = logging.getLogger('py_logs')
logger.setLevel(logging.INFO)
handler = logging.StreamHandler(stream=sys.stdout)
handler.setLevel(logging.INFO)
log_format = logging.Formatter(
    f'py_logs: %(asctime)s - %(levelname)s  %(message)s', 
    datefmt='%Y-%m-%d %I:%M:%S %p'
)
handler.setFormatter(log_format)
logger.addHandler(handler)

#logger.info('test')


config_qmax = 3
config_n_batches = 5
config_n_steps = 13
config_dur = 2 
def noise_fn(): return round(urand() - 0.5, ndigits=1)


async def worker(q, b, s, d): 
    async with q: 
        logger.debug(f"+ worker {b}-{s}, q lock: {q._value}")
        dur = d #+ noise_fn()
        await asyncio.sleep(dur) 
    logger.debug(f"- worker {b}-{s}, q free: {q._value}")
    return d

async def dispatcher(qmax, n_batches, n_steps, dur): 
    queue = asyncio.Semaphore(qmax)
    logger.info(f"job dispatched")
    results = []
    for b in range(n_batches): 
        logger.info(f"++ batch {b}, queue open: {queue._value}") 
        tasks = []
        for s in range(n_steps): 
            tasks.append(asyncio.create_task(worker(queue, b, s, dur)))
        await asyncio.gather(*tasks)
        results.append(b)
        logger.info(f"-- batch {b}") 
        await asyncio.sleep(0.5) 
    logger.info(f"finished all batches") 
    return results

def job(): 
    qmax = config_qmax
    n_batches = config_n_batches
    n_steps = config_n_steps
    dur = config_dur
    seq_max = (dur * n_steps + 0.5) * n_batches
    q_eta = (dur * math.ceil(n_steps/qmax) + 0.5) * n_batches
    logger.info(f"starting job, worst-case {seq_max} seconds") 
    logger.info(f"estimated {q_eta} seconds with async queue") 
    jstart = time.time()
    out = asyncio.run(dispatcher(qmax, n_batches, n_steps, dur))
    jdur = round(time.time() - jstart, ndigits=1)
    logger.info(f'finished job in {jdur}s; overhead {round(jdur - q_eta, ndigits=1)}')
    return out 


def seq_worker(b, s, d): 
    logger.debug(f"+ worker {b}-{s}")
    dur = d #+ noise_fn()
    time.sleep(dur) 
    logger.debug(f"- worker {b}-{s}")
    return d

def seq_dispatcher(n_batches, n_steps, dur): 
    logger.info(f"job dispatched")
    results = []
    for b in range(n_batches): 
        logger.info(f"++ batch {b}") 
        tasks = []
        for s in range(n_steps): 
            tasks.append(seq_worker(b, s, dur))
        results.append(b)
        logger.info(f"-- batch {b}") 
        time.sleep(0.5) 
    logger.info(f"finished all batches") 
    return results

def seq_job(): 
    n_batches = config_n_batches
    n_steps = config_n_steps
    dur = config_dur
    seq_max = (dur * n_steps + 0.5) * n_batches
    logger.info(f"starting job, worst-case {seq_max} seconds") 
    jstart = time.time()
    out = (seq_dispatcher(n_batches, n_steps, dur))
    jdur = round(time.time() - jstart, ndigits=1)
    logger.info(f'finished job in {jdur}s; overhead {round(jdur - seq_max, ndigits=1)}')
    return out 


run = job() 
seq_run = seq_job()


run
seq_run

