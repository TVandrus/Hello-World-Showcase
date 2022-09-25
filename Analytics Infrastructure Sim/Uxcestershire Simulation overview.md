# Uxcestershire Simulation 
naming credit: David Rudlin



Purpose: tech showcase to test interoperability of many elements of a modern data environment. Sufficient scale that modularity, organisation, and perhaps performance considerations will be relevant to scalability 


## Persistent data written to and retrieved from PostgreSQL instance 


## dagster deployment to orchestrate/execute the pipeline from setup to consumption

- setup/clean-slate job (wipe database, load seed data)
- graph to read-simulate-write an iteration of one aspect 
- graph of graphs to coordinate multiple aspects of simulation 
- job to run dbt for output 


## Simulation logic written in Julia scripts, given state returns next state

Each simulated process can yield a full data life-cycle 

Ideas: 
    - industrial production (UXDM - Uxcestershire Data Mine) 
    - retail sales (UXFSI - Uxcestershire Financial Services Inc.) 
    - transit (TUX - Transit Uxcestershire) 
    - utilities/infrastructure 
    - economy/market 
    - weather 


## dbt data model to produce consumable extracts

- seed data used to populate simulation entities
- data model to represent entities and states used by a simulation aspect 
- views for consumption/analytics 

Some underlying/reusable entities inherent to Uxcestershire: 
    - inhabitants 
    - addresses (unit, street#, street name, postal code, district) 
    - calendar (360-days per year, 30-days per month) 
    - activities (education, occupation, services, leisure) 


## Visualize extracts with Excel/Tableau/Pluto notebook?

Reveal or obfuscate the generating distributions behind process outcomes