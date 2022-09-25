Simulation outlines
PDA-format


# Census of Uxcestershire
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