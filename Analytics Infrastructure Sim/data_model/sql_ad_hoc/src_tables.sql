/* design guidelines */
/*
preferred Postgres data types: (https://www.postgresql.org/docs/current/datatype.html) 
int - numeric IDs, discrete counts, binary flags 
numeric - all other numbers 
varchar(10) - internal alpha-numeric lookup codes 
text - human-readable character strings 
date - calendar date 
timestamptz(1) - calendar date w time to 0.1 seconds and timezone 

auto-generated column for every table
dbt_refresh timestamptz(1) DEFAULT CURRENT_TIMESTAMP(1) 
*/


/* seed data tables - static CSVs loaded by dbt */

drop table if exists sim_src.seed_occupation; 
create table sim_src.seed_occupation (
    occ_cd varchar(10), 
    occ_short text, 
    occ_verbose text, 
    occ_organization text, 
    occ_sector text, 
    dbt_refresh timestamptz(1) DEFAULT CURRENT_TIMESTAMP(1) 
) 

drop table if exists sim_src.seed_income; 
create table sim_src.income (
    inc_cd varchar(10), 
    inc_short text, 
    inc_verbose text, 
    inc_low numeric, 
    inc_high numeric, 
    dbt_refresh timestamptz(1) DEFAULT CURRENT_TIMESTAMP(1) 
)

drop table if exists sim_src.seed_streets; 
create table sim_src.seed_streets (
    str_id varchar(10), 
    str_name text, 
    str_num_begin int, 
    str_num_end int, 
    str_type text, 
    dbt_refresh timestamptz(1) DEFAULT CURRENT_TIMESTAMP(1) 
)

/* raw data tables - generated to initialise a simulation then loaded to a dbt source */

drop table if exists sim_src.raw_citizens; 
create table sim_src.raw_citizens (
    cit_id int, 
    full_name text, 
    f_name text, 
    l_name text, 
    mid_init text, 
    dob date, 
    occ_cd varchar(10), 
    income_cd varchar(10), 
    address_id bigint, 
    dbt_refresh timestamptz(1) DEFAULT CURRENT_TIMESTAMP(1) 
) 

drop table if exists sim_src.raw_addresses; 
create table sim_src.raw_addresses (
    addr_id int, 
    addr_type text, 
    addr_eff_dt date, 
    a_street_name text, 
    a_street_num text, 
    a_unit_num text, 
    a_city text DEFAULT 'Uxcestershire', 
    a_mail_code text, 
    dbt_refresh timestamptz(1) DEFAULT CURRENT_TIMESTAMP(1) 
) 
