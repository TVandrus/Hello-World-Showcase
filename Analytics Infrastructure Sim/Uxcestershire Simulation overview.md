# Uxcestershire Simulation 

## Premise: 

Welcome to the made-up municipality of Uxcestershire (naming credit: David Rudlin), a coherent narrative within which to contextualize data and processes. 

Purpose: tech showcase to test interoperability of many elements of a modern data environment. Sufficient scale that modularity, organisation, and perhaps performance considerations will be relevant to scalability 


## Components: 

The goal is to shoehorn several diverse tools into the process to build complexity, without creating undue complications. 
'Complications' impair clarity, robustness, or scalability.


### dagster deployment to orchestrate/execute the pipeline from setup to consumption

- setup/clean-slate job (wipe database, load seed data)
- graph to read-simulate-write an iteration of one aspect 
- graph of graphs to coordinate multiple aspects of simulation 
- job to run dbt for output 


### Simulation logic written in Julia scripts, given state returns next state

Each simulated process could yield a full data life-cycle 

Ideas: 
    - take a census (Persons, districts, occupations)
    - commercial production (UXDM - Uxcestershire Data Mine Corp)
        - product development 
        - retail sales 
        - financial investments 
    - transit (TUX - Transit Uxcestershire) 
    - economy/market (UXX - Uxcestershire Exchange)
    - weather (UXMC - Uxcestershire Meteorological Centre)

### dbt data model to produce consumable extracts

- seed data used to populate simulation entities
- data model to represent entities and states used by a simulation aspect 
- views for consumption/analytics 

Some underlying/reusable entities inherent to Uxcestershire: 
    - inhabitants (name, age, occupation, residential address, family)
    - addresses (unit, street#, street name, postal code, district) 
    - calendar (360-days per year, 30-days per month, as text yyyymmdd or serial since 20100101) 
    - activities (education, occupation, services, leisure) 


### Visualize extracts with Excel/Tableau/Pluto notebook?

Reveal or obfuscate the generating distributions behind process outcomes
- trends
- controlled experiments 
