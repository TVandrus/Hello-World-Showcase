
using Dates, Parquet2, DataFrames 

# define trading-decision logic (move to module later)
    # naive: independent uniform random choice of asset daily 
    # personality: weighted independent choices daily seeded on 'investor profile'
    # behaviour: markov process selection, weighted by the previous choice and/or outcome 

    setup_path = "S:/Datasets & Projects/LocalRepo/Sample-Projects/Analytics Infrastructure Sim/simulation_modules/run_setup";
    cd(setup_path);
    pwd()
    traders = filter(r -> r.occup_cd == "o53", DataFrame(Parquet2.readfile("ux_input/census.parquet")));
    trade_dates = filter(r -> r.bus_date, DataFrame(Parquet2.readfile("ux_input/date_labels.parquet")));
    market_data = DataFrame(Parquet2.readfile("ux_input/market_history.parquet"));

    struct Transaction 
        tx_id::Int 
        ux_id::Int 
        trade_date::Date 
        asset_id::String 
    end

    options = unique(market_data.asset_id) 

    function trade_naive(traders, trade_dates, options)
        # naive: independent uniform random choice of asset daily 
        tx::Vector{Transaction} = [];
        sizehint!(tx, length(traders)*length(trade_dates))
        tx_id = 5_000_000_000

        for t in traders 
            for td in trade_dates 
                tx_id += 1
                record = Transaction( 
                    tx_id, 
                    t, 
                    td, 
                    rand(options)
                )
                push!(tx, record) 
            end
        end
        return tx
    end

    activity_tbl = DataFrame(trade_naive(traders.ux_id, trade_dates.julia_date, options));
    Parquet2.writefile("ux_stage/trades.parquet", activity_tbl, compression_codec=:zstd)
    activity_tbl = nothing
