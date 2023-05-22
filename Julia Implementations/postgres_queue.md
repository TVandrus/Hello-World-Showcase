

https://www.prequel.co/blog/sql-maxis-why-we-ditched-rabbitmq-and-replaced-it-with-a-postgres-queue


make use of postgres ACID features 
https://www.postgresql.org/docs/current/sql-select.html#SQL-FOR-UPDATE-SHARE


```sql
drop table if exists dev.request_q ; 
create table dev.request_q ( 
    sys_id serial primary key 
    , task_id text 
    , task_type text 
    , claim_worker text 
    , publish_time timestamp not null default current_timestamp 
    , claim_time timestamp 
    , task_spec int 
) ;

insert into dev.request_q (task_id, task_type, task_spec) \
        values (v1, v2, v3)


drop table if exists dev.activity_log ; 
create table dev.activity_log ( 
    sys_id int 
    , task_id text 
    , task_type text 
    , claim_worker text 
    , publish_time timestamp 
    , claim_time timestamp 
    , start_time timestamp 
    , end_time timestamp 
    , task_spec int 
) ; 

```


define julia requestor -> publishes requests to a queue table
```julia
using LibPQ, Dates, ProgressMeter

task_generator() = round(1 + 2^(1 + 4*rand()), digits=1)

function start_publisher(ttl=10)
    pg_conn = LibPQ.Connection("postgresql://dev_user:dev_user@localhost/development_db")
    task_query = """\
        insert into dev.request_q (task_id, task_type, task_spec) \
        values (v1, v2, v3)
    """
    task_batch = "batch $(floor(Dates.now(), Dates.Second(20)))" 
    work = []
    @showprogress for task in range(length=ttl)
        task_details = ("v1" => "'$task_batch - task_$task'", 
            "v2" => "'request'", 
            "v3" => task_generator())
        push!(work, task_details)
        publish_query = replace.(task_query, task_details...)
        execute(pg_conn, publish_query)
        sleep(2)
    end
    return work
end

q = start_publisher(15)

```


```sql
--need to lock queued request records once a worker has claimed it to avoid duplication of efforts
--remaining request records in queue need to be accessible for other workers concurrently
/* worker_type */ 
/* worker_id*/ 
start transaction; 
    set transaction isolation level repeatable read; 
    /* allow queue to be appraised, a task selected, and update the task with claiming worker info 
        to all execute without risk of changes/inconsistencies due to new commits 
        by request publishers or other workers
    */
    select current_timestamp as check_time, count(*) as currently_queued
    from dev.request_q q 
    where q.task_type = 'request' 
        and q.claim_time is NULL 
    ;
    select q.sys_id, q.task_id, q.task_type, q.publish_time, q.task_spec 
    from dev.request_q q 
    where q.task_type = 'request' 
        and q.claim_time is NULL 
    order by q.publish_time asc --priority criteria: oldest
    limit 1 
    for update skip locked 
    ;
    update dev.request_q 
    set claim_time = current_timestamp, claim_worker = '$worker_id' 
    where sys_id = 
        (select q.sys_id
        from dev.request_q q 
        where q.task_type = 'request' 
            and q.claim_time is NULL 
        order by q.publish_time asc --priority criteria: oldest
        limit 1 )
    ;
    /*select current_timestamp as check_time, count(*) as currently_queued
    from dev.request_q q 
    where q.task_type = 'request' 
        and q.claim_time is NULL 
    ;*/
commit ;
```


define julia workers -> consume from queue table, concurrently but without duplication, publish output and activity log
```julia
using LibPQ, Dates 

function claim_task(worker_id, worker_type) 
    pg_conn = LibPQ.Connection("postgresql://dev_user:dev_user@localhost/development_db")
    claim_txn = """\
        start transaction; 
            set transaction isolation level repeatable read; 
            select current_timestamp as check_time, count(*) as currently_queued
            from dev.request_q q 
            where q.task_type = $worker_type 
                and q.claim_time is NULL 
            ;
            select q.sys_id, q.task_id, q.task_type, q.publish_time, q.task_spec 
            from dev.request_q q 
            where q.task_type = $worker_type 
                and q.claim_time is NULL 
            order by q.publish_time asc --priority criteria: oldest
            limit 1 
            for update skip locked 
            ;
            update dev.request_q 
            set claim_time = current_timestamp, claim_worker = '$worker_id' 
            where sys_id = 
                (select q.sys_id
                from dev.request_q q 
                where q.task_type = $worker_type 
                    and q.claim_time is NULL 
                order by q.publish_time asc --priority criteria: oldest
                limit 1 )
            ; 
        commit ; """
    
end


```
