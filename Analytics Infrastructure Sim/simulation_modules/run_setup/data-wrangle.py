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
