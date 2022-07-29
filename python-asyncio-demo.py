##################################################
# async-queue-demo.py

import random, time, asyncio
import logging

class Task():
    def __init__(self, name, success=None, attempts=None, time_extract=None, time_loading=None): 
        self.name = name
        self.success = success
        self.attempts = attempts
        self.time_extract = time_extract
        self.time_loading = time_loading


async def random_job(name='random_job', prob=1.0, max_attempts=1, avg=10.0, sd=None):
    print('hit random job')
    success = None
    attempts = 0
    elapsed = 0.0
    while (not success) and (attempts < max_attempts):
        if sd:
            dur = random.gauss(mu=avg, sigma=sd)
        else:
            dur = avg
        success = random.random() < prob
        attempts += 1
        elapsed += dur
        await asyncio.sleep(dur)
    tsk = {
        'name': name,
        'success': (success or False),
        'attempts': attempts,
        'time': elapsed
    }
    print(f"{tsk['name']} completed with {(tsk['success'] and 'success') or ('error')} after {tsk['attempts']} attempts")
    return tsk


async def extract_worker(a_queue, b_queue, worker_id):
    print(f'hit extract, queue {a_queue.qsize()} -> queue {b_queue.qsize()}')
    task_count = 0
    work_time = 0.0
    start_flag = False
    while (not start_flag):
        await asyncio.sleep(2)
        start_flag = a_queue.full()
        print(f'extract wait, queue {a_queue.qsize()}')
    print(f"Extract_{worker_id} starting")
    while (start_flag) and (not a_queue.empty()):
        extract_task = await a_queue.get()
        print(f"Extract_{worker_id} picked up {extract_task.name}")
        # do work
        start = time.perf_counter()
        data = await asyncio.gather(random_job(extract_task.name, avg=9, sd=5))
        elapsed_ext = round(time.perf_counter() - start, ndigits=1)
        extract_task.time_ext = elapsed_ext
        task_count += 1
        work_time += elapsed_ext
        print(f'{extract_task.name} extracted in {elapsed_ext} seconds')
        # pass to next queue when there is space
        if b_queue.full():
            await b_queue.put(extract_task)
        else:
            b_queue.put_nowait(extract_task)
        elapsed_wait = round(time.perf_counter() - start - elapsed_ext, ndigits=1)
        print(f"\n{extract_task.name} added to queue after {elapsed_wait} seconds waiting; {a_queue.qsize()} extract jobs queued")
        await asyncio.sleep(1) # take a break 
    print(f"Extract_{worker_id} quitting")
    return (worker_id, task_count, work_time)


async def loading_worker(a_queue, worker_id, log):
    print(f'hit loading')
    task_count = 0
    work_time = 0.0
    start_flag = False
    while not start_flag:
        await asyncio.sleep(2)
        start_flag = a_queue.full()
        print(f'loading wait, queue {a_queue.qsize()}')
    print(f"Loading_{worker_id} starting")
    while (not a_queue.empty()):
        load_task = await a_queue.get()
        print(f"Loading_{worker_id} picked up {load_task.name}\n")
        # do work
        start = time.perf_counter()
        data = await asyncio.gather(random_job(load_task.name, prob=0.66, max_attempts=5, avg=12, sd=4))
        elapsed_load = round(time.perf_counter() - start, ndigits=1)
        load_task.time_load = elapsed_load
        task_count += 1
        work_time += elapsed_load
        print(f'{load_task.name} extracted in {elapsed_load} seconds')
        # log results and release the task when done
        log.append(load_task)
        a_queue.task_done()
        await asyncio.sleep(1) # take a break 
        print(f"Loading_{worker_id} ready, queued: {a_queue.qsize()}")
    print(f"Loading_{worker_id} quitting")
    return (worker_id, task_count, work_time)


async def queue_random_tasks(n_tasks=20, extract_names=[chr(i) for i in range(97,100)], loading_names=[chr(i) for i in range(122,118,-1)]):
    print(f'{n_tasks} tasks')
    a_queue = asyncio.Queue(maxsize=min(len(extract_names), n_tasks))
    b_queue = asyncio.Queue(maxsize=min(len(loading_names), n_tasks))
    print(f'Extract workers: {extract_names} \nLoading workers: {loading_names} \nStarting ... \n')
    #
    tasks = [f'task-{i}' for i in range(n_tasks)]
    task_logs = []
    start = time.perf_counter()
    print('start timer')
    extract_jobs = [asyncio.create_task(extract_worker(a_queue, b_queue, id)) for id in extract_names]
    loading_jobs = [asyncio.create_task(loading_worker(b_queue, id, log=task_logs)) for id in loading_names]
    print('workers created')
    for tsk in tasks:
        if (not a_queue.full()):
            a_queue.put_nowait(tsk)
        else: 
            await a_queue.put(tsk)
        print('.', end='')
    print('tasks queued')
    extract_report = await asyncio.gather(*extract_jobs, return_exceptions=True) 
    loading_report = await asyncio.gather(*loading_jobs, return_exceptions=True) 
    a_queue.join()  # implicitly waits until queue is cleared
    b_queue.join()
    elapsed = round(time.perf_counter() - start, ndigits=0)
    print('\nJobs done')
    #
    for e in extract_jobs: 
        e.cancel()
    for l in loading_jobs: 
        l.cancel()
    print('Workers released')
    results = sum([lg.success for lg in task_logs])
    # return logged information
    print(f'Completed queue of tasks in {elapsed} seconds clock-time')
    print(results + ' of ' + n_tasks + 'tasks succeeded')
    print(extract_report)
    print(loading_report)


# test
#asyncio.run(random_job())

asyncio.run(queue_random_tasks(n_tasks=20, extract_names=['W','X','Y'], loading_names=['Thomas','Terry','Teng','Dweit']))

