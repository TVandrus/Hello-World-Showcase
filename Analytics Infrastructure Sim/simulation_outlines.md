Simulation outlines
PDA-format

# Design/Roadmap

Sources -> Ingest to workspace -> Src -> Simulation preprocess -> Simulation generate -> Load/Update analytics workspace -> Analysis

Sources 
    requires: ideas/definitions
    materialized: folder of local files
    result: ready for ingest to pipeline workspace 

Src 
    requires: extract from Sources, assert minimal standards 
    materialized: persistent, allow concurrent reads
    result: accessible in catalog of tables

Simulation preprocess/initialization 
    requires: Src data, schema/normalization logic
    materialization: high bulk-write throughput, fast query-subset performance (indexed?)
    result: all inputs needed to initialize the simulation processes

Simulation generate 
    requires: logic to represent Uxcestershire processes from staged data 
    materialization: high-performance read->assemble->write loop for activity records (portable/in-process DB, or in-memory)
    result: activity records loaded to analytics workspace

Load/Update analytics workspace 
    requires: activity records from simulation 
    materialization: optional performance/caching layer 
    result: cataloged write-once-read-many data store 

Analysis
    requires: activity records from processes in-context 
    materialization: visuals in notebook/dashboard format 
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


