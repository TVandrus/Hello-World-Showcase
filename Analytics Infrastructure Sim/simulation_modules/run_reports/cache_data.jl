
using DataFrames, Parquet2, LibPQ, ProgressMeter, Dates 


pwd() # Sample-Projects/
cd("Analytics Infrastructure Sim/simulation_modules/");

@info ("Starting - $(Dates.now())")

# need more performant loading than Python
    fdir = "run_simulation/ux_stage/"; 
    tname = "trades"; # ~143 million records of 4-field Transactions 

    df = DataFrame(Parquet2.readfile(fdir * tname * ".parquet"));
    N = nrow(df) 

    batch_size = 50_000;
    row_strings::Vector{String} = [];
    sizehint!(row_strings, batch_size)

    conn = LibPQ.Connection("postgresql://dev_user:dev_user@localhost/development_db")
    execute(conn, "truncate table $("ux_stage."*tname)")
    
    @showprogress for p in Iterators.partition(df, batch_size)
        row_strings = []
        for r in eachrow(p) 
            push!(row_strings, "$(r.tx_id),$(r.ux_id),$(r.trade_date),$(r.asset_id)\n") 
        end   
        copyin = LibPQ.CopyIn("COPY $("ux_stage."*tname) FROM STDIN (FORMAT CSV);", row_strings)
        execute(conn, copyin)
    end 
    close(conn)

