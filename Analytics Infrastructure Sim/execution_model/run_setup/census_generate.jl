"""
Setup the simulation to bring Uxcestershire to life
"""

# MVP: simulate a trading industry
# requires: 
    # 1 Inhabitants of UX working in finance 
    # 2 define time period for activity 
    # 3 basis for trading returns 
    # 4 logic to generate activity for each step/state 
    # 5 container for record of activities 

"""
Municipality of Uxcestershire: 

current population ~500_000
    50_000 university students
    100_000 young students 
    350_000 adults
        250_000 working
        100_000 at home or retired
~250_000 residential units 
"""


using Dates, CSV, Parquet, DataFrames 


# take a census to discover the population 
struct Person
    ux_id::Integer 
    first_name::String 
    last_name::String 
    bth_date::Date 
    occup_cd::String 
    #address_id::Integer 
end

sim_start = Date(2010, 1, 1) 
sim_end = Date(2021, 1, 1) 
sim_step = Day(1)

function pq_date(d::Date)::Int32 
    #=
    Signed Int32 relative to Unix Epoch  
    Used for Parquet 
    =#
    return Dates.value(d - Date(1970, 1, 1))
end


pwd() # ux_src/
src_names = CSV.File("full_names.csv");

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
    return census 
end

# convert vector of tuples to column-accessible Table
census_vec = ux_census();
census_tbl = DataFrame(census_vec);
summary(census_tbl)
census_tbl[1:10, :]
census_tbl.bth_date = pq_date.(census_tbl.bth_date); # dates for parquet standard
write_parquet("ux_input/census.parquet", census_tbl, compression_codec="ZSTD") 


# generate/pre-calculate market returns for a basket of assets to cover the full simulation period 




# define trading-decision logic

    # naive: independent uniform random choice of asset daily 
    # personality: weighted independent choices daily seeded on 'investor profile'
    # behaviour: markov process selection, weighted by the previous choice and/or outcome 
