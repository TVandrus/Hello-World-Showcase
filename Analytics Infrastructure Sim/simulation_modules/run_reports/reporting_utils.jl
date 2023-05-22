using LibPQ, ProgressMeter, Dates, Decimals 
using DataFrames, Plots, StatsPlots #,GR, PythonPlot, PlotlyJS, , Distributions

# precursor for interactive notebook format 
#using Pluto


# data retrieval template
pg_conn = LibPQ.Connection("postgresql://dev_user:dev_user@localhost/development_db");

query_txt = Vector{String}(undef, 100); # preallocate for tidiness, without mutation 
plt = Vector{Plots.Plot}(undef, 100); 
query_tbl(query_txt; strict=true) = DataFrame(execute(pg_conn, query_txt, []; not_null=strict)); 


query_txt[1] = "select distinct asset_id from ux_input.market_history order by asset_id asc"; 
query_tbl(query_txt[1], strict=true)


# enter range of julia dates 
period = (Date(2010, 1, 1), Date(2015, 1, 1));
# enter julia string representing SQL-list of SQL-strings 
assets = "'can10yrbond','can5yrbond', 'can1yrbond','djia','dowglobal','nysefin'"; 


query_txt[2] = """\
    with prc_start as (
        select asset_id, case when prc_open = 0 then 1 else prc_open end prc_start
        from ux_input.market_history 
        where prc_date = '$(period[1])' 
            and asset_id in ($(assets)) 
    )
    select mh.asset_id, mh.prc_date, cast(round(case when mh.prc_open <> 0 then mh.prc_open else 1 end / ps.prc_start, 4) as float) as "prc_rel"
    from ux_input.market_history mh 
        join prc_start ps on ps.asset_id = mh.asset_id 
    where mh.prc_date between '$(period[1])' and '$(period[2])' 
    order by mh.prc_date
"""; 

df = query_tbl(query_txt[2]); 

plt[2] = @df df Plots.plot(    
    :prc_date, 
    :prc_rel, 
    group=:asset_id,
    title="Asset price performance",
    xlabel="Sim Date",
    ylabel="Relative Price"
)





