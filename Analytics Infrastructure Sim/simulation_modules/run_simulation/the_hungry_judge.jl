
using DataFrames, Dates, ProgressMeter, CSV, DuckDB

n_txn = 1_000;
txn_id0 = 6_000_000;
period_start = Date(2020, 1, 1)
period_end = Date(2020, 12, 30)
MORNING = 7:11;
MIDDAY = 11:4;
EVENING = 4:9;

SMALL_ORDER = (mu=5, sigma=3);
LARGE_ORDER = (mu=15, sigma=10);

menu = DataFrame(CSV.File("Analytics Infrastructure Sim/simulation_modules/run_simulation/the_hungry_judge_menu.csv"));

struct SaleTransaction
    tx_id::Int 
    tx_sub_id::Int
    ux_id::Int 
    pymt_id::Int
    tx_date::Date 
    tx_time::Time 
    item_id::String 
    item_price::Number 
end


function find_client()

end


function find_date()

end 


function find_order()

end

for t in 1:n_txn
    t_id = txn_id0 + t
    ux_id = find_client()


end
