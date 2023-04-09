import pyspark as ps 
import pyspark.sql as psql
import pandas as pd 
import os


# setup 
os.environ['JAVA_HOME'] = "S:\\Java\\jdk-20"
os.environ['SPARK_HOME'] = "S:\\ApacheSpark\\spark-3.3.2-bin-hadoop3"
os.environ['HADOOP_HOME'] = "S:\\ApacheSpark\\spark-3.3.2-bin-hadoop3"
os.environ['PYTHONPATH'] = "S:\\ApacheSpark\\spark-3.3.2-bin-hadoop3\\python"
os.environ['PYTHONPATH'] += "; S:\\ApacheSpark\\spark-3.3.2-bin-hadoop3\\python\\lib\\py4j-0.10.9.5-src.zip"
os.environ['PYSPARK_PYTHON'] = "S:\\Python\\Python_3_10\\python.exe"

# instantiate local cluster w 3 threads
#   use [*] for all available logical cores per os.cpu_count()
connect_session = psql.SparkSession.builder\
    .master("local[3]")\
    .appName("spark_poc_X")\
    .getOrCreate()


connect_session.sparkContext

"""
SparkUI monitoring 
$env:SPARK_HOME = "S:\\ApacheSpark\\spark-3.3.2-bin-hadoop3"
$env:HADOOP_HOME = $env:SPARK_HOME
."S:/ApacheSpark/spark-3.3.2-bin-hadoop3/bin/spark-shell.cmd"

http://localhost:4041
"""

# verify configuration
# https://realpython.com/pyspark-intro/#hello-world-in-pyspark
txt = connect_session.sparkContext.textFile("file:///S:/Python/Python_3_10/LICENSE.txt") # lazy graph
print(txt.count()) # executes graph when output requested
python_lines = txt.filter(lambda line: 'python' in line.lower())
print(python_lines.count())


# define Spark SQL session for working with tables/structured data
sparks = connect_session

# read Parquet to DataFrame
pqdf = sparks.read.parquet("file:///S:/Datasets & Projects/LocalRepo/Sample-Projects/Analytics Infrastructure Sim/execution_model/run_setup/ux_input/census.parquet")
pqdf.show()

# query any DataFrame with SQL statements by referencing as a view
pqdf.createOrReplaceTempView("ParquetTable")
pqSQL = sparks.sql("select * from ParquetTable limit 75;")
pqSQL.count()
pqSQL.show(n=25)


# save DataFrame to Parquet file 
out_path = "S:/Datasets & Projects/LocalRepo/Sample-Projects/Analytics Infrastructure Sim/execution_model/run_setup/ux_input/converted"
pddf = pd.DataFrame(pqdf.collect(), columns=pqdf.columns)

pddf.to_parquet(path=out_path+".lz4", compression='lz4', index=False)
pddf.to_parquet(path=out_path+".zstd", compression='zstd', index=False)
pddf.to_parquet(path=out_path+".gzip", compression='gzip', index=False)
pddf.to_parquet(path=out_path+".snap", compression='snappy', index=False)
pddf.to_csv(path_or_buf=out_path+".csv", encoding='utf-8', index=False)

os.getcwd()
target = os.path.join(os.getcwd(), "Analytics Infrastructure Sim/execution_model/run_setup/ux_input/")
os.chdir(target)
target_name = "direct_write.file"

pqdf.write.parquet(path="pyspark_write.file")


import pyspark.files as psf


ps.SparkFiles.get()

# end 