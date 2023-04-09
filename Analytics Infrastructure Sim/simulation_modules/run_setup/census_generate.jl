"""
Setup the simulation to bring Uxcestershire to life

Municipality of Uxcestershire: 
    current population ~500_000
        50_000 university students
        100_000 young students 
        350_000 adults
            250_000 working
            100_000 at home or retired
        ~250_000 residential units 
"""

using Dates, CSV, Parquet2, DataFrames 

# prerequisite: wrangle raw data into valid/semi-structured form in ux_src/ 
setup_path = "S:/Datasets & Projects/LocalRepo/Sample-Projects/Analytics Infrastructure Sim/simulation_modules/run_setup";
cd(setup_path);
pwd() 
readdir() # ux_src/, ux_input/ 

# MVP: simulate a trading industry
# requires: 
    # 1 Inhabitants of UX working in finance 
    # 2 define time period for activity 
    # 3 basis for trading returns 
    # 4 logic to generate activity for each step/state 
    # 5 container for record of activities 

# pre-defined conveniences/utilities
    struct Person
        ux_id::Integer 
        first_name::String 
        last_name::String 
        bth_date::Date 
        occup_cd::String 
        #address_id::Integer 
    end

    struct Asset 
        asset_id::String 
        prc_date::Date 
        prc_open::Float64 
        prc_close::Float64 
        asset_return::Float64 
    end

    function pq_date(d::Date)::Int32 
        #=
        Signed Int32 relative to Unix Epoch  
        Used for Parquet 
        =#
        return Dates.value(d - Date(1970, 1, 1))
    end


##################################################
# simulation parameters
    sim_start = Date(2010, 1, 1) 
    sim_end = Date(2021, 1, 1) 
    sim_step = Day(1)

##################################################


# explicit listing of dates for the simulation period
    function date_map(sim_start, sim_end)::DataFrame
        sim_days = 1 + Dates.value(sim_end - sim_start)
        ind::Vector{Int} = Vector(undef, sim_days);   
        dd::Vector{Date} = Vector(undef, sim_days);  
        di::Vector{Int} = Vector(undef, sim_days);  
        ds::Vector{String} = Vector(undef, sim_days);  
        dp::Vector{Int} = Vector(undef, sim_days); 
        db::Vector{Bool} = Vector(undef, sim_days); 

        i::Int = 1; 
        d::Date = sim_start; 
        while d <= sim_end
            ind[i] = i 
            dd[i] = d 
            di[i] = Dates.value(d) 
            dp[i] = pq_date(d)
            ds[i] = string(d)
            db[i] = (Dates.dayofweek(d) in 1:5) 
            i += 1
            d += Day(1)
        end 
        dmap = (sim_date=ind, julia_date=dd, int_date=di, parq_date=dp, string_date=ds, bus_date=db)
        return DataFrame(dmap)
    end

    dates_tbl = date_map(sim_start, sim_end);
    summary(dates_tbl)
    describe(dates_tbl)
    dates_tbl[1:10, :]
    Parquet2.writefile("ux_input/date_labels.parquet", dates_tbl, compression_codec=:uncompressed)

    check = DataFrame(Parquet2.readfile("ux_input/date_labels.parquet"));
    describe(check)


# take a census to discover the population 
    src_names = CSV.File("ux_src/full_names.csv");

    function ux_census(
            n::Integer = 50_000, 
            )::Vector{Person} 
        """
        generate sections/demographics of inhabitants 
        """
        census::Vector{Person} = []
        sizehint!(census, n)
        
        # generate attributes by sampling from defined space 
        fin_cd = "o53" # financial trader

        # ages 25-55 at start of sim 
        bth_latest = Date(1985,1,1) 
        bth_earliest = Date(1955,1,1) 
        spc = range(0, (bth_latest - bth_earliest).value) 
        spl = rand(spc, n); 
        bth_dates = bth_earliest .+ Day.(spl);

        spc = range(1, length(src_names))
        spl_names = rand(spc, n);

        for i in 1:n
            p = Person(
                1_000_000_000+i, 
                src_names[spl_names[i]][1],
                src_names[spl_names[i]][3],
                bth_dates[i], 
                fin_cd, 
            )
            push!(census, p)
        end
        # convert vector of tuples to column-accessible Table
        return census 
    end

    census_tbl = DataFrame(ux_census());
    summary(census_tbl)
    census_tbl[1:10, :]
    #census_tbl.bth_date = pq_date.(census_tbl.bth_date); # dates for parquet standard
    #write_parquet("ux_input/census.parquet", census_tbl, compression_codec="ZSTD") 
    Parquet2.writefile("ux_input/census.parquet", census_tbl, compression_codec=:uncompressed);
    check = DataFrame(Parquet2.readfile("ux_input/census.parquet"))
    describe(check)


# generate/pre-calculate market returns for a basket of assets to cover the full simulation period 
    setup_path = "simulation_modules/run_setup"; 
    cd(setup_path);
    sim_dates = DataFrame(Parquet2.readfile("ux_input/date_labels.parquet"));
    market_days = filter(x -> x[:bus_date], sim_dates); 
    describe(market_days)

    src_path = "ux_src/market_prices/";
    readdir(src_path)
    cd(src_path);

    """
    for all simulation business dates, match the price data 
    for missing dates (presumed holidays) keep the previous close, no change 
    """
    dfmt = dateformat"mm/dd/yy"
    price_history::Vector{Asset} = [];

    for f in readdir()
        dat = DataFrame(CSV.File(f))
        asset_id = split(f, "-")[1]
        asset_history::Vector{Asset} = []
        #info = "$asset_id \t- $(size(dat)[1]) \t- $(minimum(dcol)) to $(maximum(dcol))"
        #println(info)
        for rw in (eachrow(dat)) 
            #rw = (eachrow(dat))[1]
            cln = Asset( 
                asset_id, 
                Date(rw.Date, dfmt) + Year(2000), 
                rw[Symbol(" Open")], 
                rw[Symbol(" Close")], 
                round(rw[Symbol(" Close")] / rw[Symbol(" Open")], digits=4) 
            )
            push!(asset_history, cln)
        end
        # for missing dates (presumed holidays) keep the previous close, no change
        df_part = DataFrame(asset_history); 
        misses = antijoin(market_days, df_part, on= :julia_date => :prc_date); 
        size(misses)
        for mrw in eachrow(misses)
            prev = maximum(filter(d -> d < mrw.julia_date, df_part.prc_date), init=minimum(df_part.prc_date))
            filler = filter(r -> r.prc_date == prev, df_part)[1, :]::DataFrameRow
            cln = Asset( 
                asset_id, 
                mrw.julia_date, 
                filler.prc_close, 
                filler.prc_close, 
                1.0
            ) 
            push!(asset_history, cln)
        end
        append!(price_history, asset_history)
    end
    market_tbl = DataFrame(price_history)

    cd(setup_path);
    Parquet2.writefile("ux_input/market_history.parquet", market_tbl, compression_codec=:uncompressed); 
    
    check = DataFrame(Parquet2.readfile("ux_input/market_history.parquet"));
    describe(check)
    unique(check.asset_id)
