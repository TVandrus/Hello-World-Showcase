
import pandas as pd
import os, random, time
# define trading-decision logic (move to module later)
# naive: independent uniform random choice of asset daily 
# personality: weighted independent choices daily seeded on 'investor profile'
# behaviour: markov process selection, weighted by the previous choice and/or outcome 

sim_path = "S:/Datasets & Projects/LocalRepo/Sample-Projects/Analytics Infrastructure Sim/simulation_modules/"
os.chdir(sim_path)
os.getcwd()

# class Transaction: 
#     def __init__(self, tx_id, ux_id, trade_date, asset_id): 
#         self.tx_id = tx_id
#         self.ux_id = ux_id 
#         self.trade_date = trade_date 
#         self.asset_id = asset_id 


def trade_naive(traders, trade_dates, options): 
    # naive: independent uniform random choice of asset daily 
    tx = []
    tx_id = 5_000_000_000
    for t in traders: 
        for td in trade_dates: 
            tx_id += 1
            # record = Transaction( 
            #     tx_id, 
            #     t, 
            #     td, 
            #     random.sample(options, 1)[0]
            # ) # took 28min, couldn't convert to DataFrame 
            record = dict(
                tx_id=tx_id, 
                ux_id=t, 
                trade_date=td, 
                asset_id=random.sample(options, 1)[0]
            ) # crashed from memory error after 5min 
            tx.append(record)
    return tx

print("starting ", time.localtime())
df = pd.read_parquet("run_setup/ux_input/census.parquet")
traders = df.loc[[r == "o53" for r in df.occup_cd]]
df = pd.read_parquet("run_setup/ux_input/date_labels.parquet")
trade_dates = df.loc[df.bus_date]
df = pd.read_parquet("run_setup/ux_input/market_history.parquet")
options = list(df.asset_id.unique())

print("ready ", time.localtime())
activity_tbl = pd.DataFrame(trade_naive(traders.ux_id, trade_dates.julia_date, options))
print("saving ", time.localtime())
activity_tbl.to_parquet("run_simulation/ux_stage/trades_copy.parquet", compression='zstd')
print("done ", time.localtime())

"""
Benchmarked 2023-04

cumulative execution time based on timestamps

Stage       Julia       Python
Start       00:00       00:00 
Ready       00:17       00:02 
Saving      00:25       ...
Done        01:08       ...
"""