Simulation outlines
PDA-format

# Design/Roadmap

Sources -> Ingest to workspace -> Src -> Simulation preprocess -> Simulation generate -> Load/Update analytics workspace -> Analysis

ux_rawdata -> ux_src -> ux.input -> ux.stage -> ux.output

## Raw Data Sources 
    requires: ideas/definitions
    materialized: folder of local files
    result: ready for ingest to pipeline workspace 
        - ux/rawdata/

## Cleaned Data Samples 
    requires: extract from Sources, assert minimal standards 
    materialized: persistent, allow concurrent reads
        - database? 
        - filestore? 
    result: accessible catalog of tables
        - ux.src
        - name parts
        - address parts 
        - transit/trip records 
        - retail/sales records 
        - asset price records 
        - git contribution records 
        - effective dates (start, end, step_length) 
            - 2010-2020?
        - world conditions by date (weather, holidays, daylight, or overall activity-level index from parking violations/trade volume?)

## Simulation preprocess/initialization 
    requires: Src data, schema/normalization logic 
        - Person = uxid, name, occupation, [demographic: age, address, income]
        - Address = id, unit, street_num, street_name, [district, post_code, geospatial] 
        - 
    materialization: high bulk-write throughput, fast query-subset performance 
        - dbt on Postgres?
    result: all inputs needed to initialize the simulation processes
        - ux.input
        - data to generate Persons w uxid
        - mapping or corpus for any attributes [occupation, occupation org, income, address]
        - corpus of activity records to sample from 
        - event schedule/trigger generator 
            - random activity suggested each step, accept/reject on propensity
        - Person-event propensity/matching

## Simulation generate 
    requires: logic to represent Uxcestershire processes from staged data 
    materialization: high-performance [query-read -> assemble -> write] loop for activity records 
        - portable DB SQLite?
        - in-process DB DuckDB?
        - in-memory tables Arrow/Feather?
    result: activity records ready to load to analytics workspace
        - ux.stage

## Load/Update analytics workspace 
    requires: activity records from simulation 
    materialization: optional performance/caching layer 
        - indexed on date, record_id, Person uxid 
    result: cataloged write-once-read-many data store 
        - ux.output

## Analysis
    requires: activity records from processes in-context 
    materialization: visuals in notebook/dashboard format 
        - Pluto.jl 
    result: tell a story


# Modules
## Census of Uxcestershire
Purpose: 
    census, with disorganised, ambiguous, duplicated, or erroneous data 
    establish process for generating rich population
    MVP for full architecture

Data: 
    records from goverment (missing values) 
    residential collection (full population, messy data)
    place of occupation (duplicates, ambiguous, additional mapping) 

    individual entity: 
        unique id [1xxxxxx]
        full name 
        date of birth 
        family/household id [2xxxxxx]/NULL
        address record id [3xxxxxx] 
            unit num ['ffuu']
            street num [100-1100]
            street name [5-20 char]
            street type [Avenue,Boulevard,Crescent,Drive,Edge,Flight,Glen,Street,Way] 
            street section [North/South,East/West] 
            post code ['ABC']  
            district [301-320]  
        occupation record id [4xxxxxx] 
            segment: training, working, not-working
            institution: [UXU, UXDM/UXFS, NULL] 
            start date 
            end date [NULL]

Analysis: determine unique individuals and store enriched records
    - generate complete truth from seed sources (individuals, addresses, institutions)
    - derive noisy extracts 
    - attempt to de-noise and recreate original
    - query and display results


