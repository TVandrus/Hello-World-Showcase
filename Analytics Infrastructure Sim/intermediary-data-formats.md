# Intermediary Formats for Data Pipeline
2023-02

- need to have data exist other than the organized source system (for consumption, analysis, transformation, or transfer) 
- many different formats exist, widely varying performance profiles 
- attempt to note important characteristics that make a format suitable/unsuitable for a given application 
- attempt to provide reproducible comparisons of relevant examples to test across different hardware 


## Key Factors: 

- object size on-disk 
- bulk writes/reads (full table)
- complex reads (subsets) 
- complex writes (conditional updates, appending) 
- in-memory footprint 
- compute requirements 
- languages w encode/decode support 
- interoperability & preservation of features 


https://betterdatascience.com/top-csv-alternatives/ 
https://towardsdatascience.com/demystifying-the-parquet-file-format-13adb0206705


~2GB
source = "S:/Datasets & Projects/NY Parking Violations/Parking_Violations_Issued_-_Fiscal_Year_2019.csv"

using CSV, DataFrames
@time x = CSV.read(source, DataFrame); 


## Formats


### CSV (UTF-8 standard) 
Universal storage/accessible format for tabular structured data. 
Reference point for all aspects of performance. 

- no compression
- low compute needs, high bandwidth 
- bulk read/write is bandwidth-limited 
- partial read is very slow 
- partial write can be quick 
- large in-memory footprint, better to convert or map from disk to memory
- minimal compute requirements
- 100% support/compatibility for all use cases 


### Excel 
Two relevant options: standard .XLSX, and binary .XLSB 

- standard is lightly compressed XML, binary has stronger, proprietary compression and handles complex files 
- extra compute & size overhead for small files, scales well for medium-size in terms of bandwidth and compute, not good over 0.5GB 
- all operations require whole-file loading
- moderate in-memory performance
- moderate compute requirements 
- limited encode/decode options (Excel, MS Office suite, VBA, ~Powershell, ~Python) 
- not easily converted 


### Parquet 
Data storage format for modern data workflows. 

- efficient compression options
- mix of bandwidth and compute for bulk read/write 
- very efficient querying reads 
- partial writes?
- optimized for on-disk persistent storage 
- moderate compute overhead 
- broad encode/decode support w Python & AWS (Tableau?) 
- good for cloud, data tools, not for Microsoft ecosystem 


### Python Pickle 
Python's native binary encoding format for arbitrary Python objects

- efficient compression 
- mix of bandwidth and compute for bulk read/write 
- not designed for partial read/writes (save multiple objects instead) 
- suitable for on-disk storage, but not long-term archiving (due to compatibility) 
- memory/compute based on native Python objects 
- limited to use by Python 
- no conversion/interoperability 


### SQLite 
Portable storage file format for serverless access via SQL operations 

- compression?
- large single-file access for all read/write operations
- more efficient querying, updating via SQL 
- memory footprint? 
- moderate compatibility (Python) 
- partial SQL-standard interoperability 


### Arrow 
Tabular format for highly-optimized in-memory performance 


### Feather 
Wrapper/protocol for writing Arrow objects to persistent file storage 



### PostgreSQL (AWS Redshift?)
Full-featured transactional relational database 





### Pandas DataFrame
Standard/benchmark for in-memory handling of tabular data in Python, very flexible. 


### DataFrames.jl 

### DataTable.jl

### R Data.Frame 

### R Data.Table 
