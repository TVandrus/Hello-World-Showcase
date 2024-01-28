using DataFrames, Dates, ProgressMeter, CSV

n_txn = 1_000;
txn_id0 = 6_000_000;
menu = []
period_start = Date(2020, 1, 1)
period_end = Date(2020, 12, 30)
MORNING = 7:11;
MIDDAY = 11:4;
EVENING = 4:9;

SMALL_ORDER = (mu=5, sigma=3)
LARGE_ORDER = (mu=15, sigma=10)

menu = DataFrame(CSV.File("the_hungry_judge_menu.csv"));

for t in 1:n_txn
    
end
