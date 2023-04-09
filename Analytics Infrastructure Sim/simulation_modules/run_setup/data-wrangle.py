import os, typing as tp
import csv, json, pandas, pyarrow
import datetime 


os.getcwd()
os.listdir()


# person names corpus 
pnames = pandas.read_json('last_names.json', orient='index')
ntxt = list(pnames.index)

result: tp.List[str] = []
for i in ntxt:
    if (ord(i[0]) in range(65, 90)) and (ord(i[1]) in range(97, 122)):
        result.append(i)

len(result)
df = pandas.DataFrame({"first_name": result})
df.to_csv('last_names_valid.csv')



# asset trading price history
prices = ['can10yrbond-prices.csv', 'can1yrbond-prices.csv', 'can5yrbond-prices.csv', 'djia-prices.csv', 'dowglobal-prices.csv', 'nasdaqcomp-prices.csv', 'nasdaqtech-prices.csv', 'nyseenergy-prices.csv', 'nysefin-prices.csv', 'russel3000-prices.csv']
results = []
for f in prices:
    df = pandas.read_csv(f)
    asset = f.split("-")[0]
    df = df[["Date"," Open"," Close"]]
    df.columns = ['price_date','price_open','price_close']
    df["asset"] = asset
    df.head()
    results.append(df)

compiled = pandas.concat(results, axis=0)
compiled.to_csv('prices_combined.csv')
