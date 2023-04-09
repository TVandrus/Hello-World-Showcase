

/*
drop table if exists ux_stage.TABLE_NAME; 
create table ux_stage.TABLE_NAME (
    ux_id int
);
*/

drop table if exists ux_input.census; 
create table ux_input.census (
    ux_id bigint 
    , first_name text
    , last_name text 
    , bth_date date 
    , occup_cd text 
);

drop table if exists ux_input.date_labels; 
create table ux_input.date_labels (
    sim_date int 
    , julia_date date
    , int_date int 
    , parq_date int 
    , string_date text 
    , bus_date boolean 
); 

drop table if exists ux_input.market_history; 
create table ux_input.market_history (
    asset_id text 
    , prc_date date 
    , prc_open numeric
    , prc_close numeric 
    , asset_return numeric 
); 



drop table if exists ux_stage.trades; 
create table ux_stage.trades (
    tx_id bigint 
    , ux_id bigint 
    , trade_date date 
    , asset_id text 
); 

