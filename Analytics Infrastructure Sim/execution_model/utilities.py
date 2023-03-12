import dagster as dag
import sqlalchemy as sqa
import pandas as pd 
import asyncio, sys, os, shutil, subprocess, logging


dlog = dag.get_dagster_logger()

logger = logging.getLogger('py_logs')
logger.setLevel(logging.INFO)
handler = logging.StreamHandler(stream=sys.stdout)
handler.setLevel(logging.INFO)
log_format = logging.Formatter(
    f'py_logs: %(asctime)s - %(levelname)s  %(message)s', 
    datefmt='%Y-%m-%d %I:%M:%S %p'
)
handler.setFormatter(log_format)
logger.addHandler(handler)
#logger.info('test')


def run_powershell(ps_txt=None, exec_path=None, log_out=logger): 
    """
    Run a Powershell script in a subprocess spawned by Python
    Streams STDOUT to the given log handler
    
    If logging of multiple streams is needed, look for an asyncio implementation to avoid blocking on one stream
    https://stackoverflow.com/a/59041913
    """
    if exec_path:
        ps_txt = f"cd {exec_path}; \n{ps_txt} "
    logs = []
    try: 
        proc = subprocess.Popen(["powershell.exe", ps_txt], stdout=subprocess.PIPE)
        while proc.poll() is None:
            line = proc.stdout.readline()
            if line:
                line_txt = line.decode("utf-8").strip() 
                logs.append(line_txt)
                log_out.info(line_txt)
        return logs # 
    except subprocess.SubprocessError:
        log_out.error("subprocess failed during execution, non-zero exit status")


def run_julia(jl_txt='print("hello julia")', exec_path=None, jl_include=None):
    from juliacall import Main as jl
    os.environ['PYTHON_JULIACALL_THREADS'] = '3'
    #jl.Threads.nthreads()

    try: 
        if exec_path:
            os.chdir(exec_path)
    except: 
        print("could not navigate to the requested directory for execution") 

    try:
        for dep in jl_include:
            jl.include(dep) 
    except:
        print("issue loading the requested dependencies") 

    try: 
        jl.seval(jl_txt)
    except: 
        print("the given Julia code was unable to run") 


class DataPipe:
    """
    collection of methods to move data around from one form to another
    unlike a generic object, assert that there is metadata providing a sense of direction for the data in the pipe in addition to its current state
    applies opinionated defaults for convenience/consistency, otherwise pick your own options: https://pandas.pydata.org/docs/reference/index.html  
    """
    def __init__(self): 
        self.src_name: str = ''
        self.src_format = None # one of storage_types 
        self.dest_name: str = ''
        self.dest_format = None # one of storage_types 
        self.obj = None # data object represented by rows and columns 
        self.obj_format: str = 'uninit' # one of mem_types
        return self

    def __init__(self, metadata: dict):
        self.src_name: str = metadata.get('src_name', 'data')
        self.src_format = metadata.get('src_format') # one of storage_types 
        self.dest_name: str = metadata.get('dest_name', self.src_name)
        self.dest_format = metadata.get('dest_format') # one of storage_types 
        self.obj = metadata.get('obj') # data object represented by rows and columns 
        self.obj_format: str = metadata.get('obj_format') # one of mem_types
        return self
        
    store_types = set(
        'csv', # convenient, inefficient
        'excel', # convenient, situational 
        'feather', # performant, scalable 
        'parquet', # performant, scalable 
        'sql' # convenient 
        )
    mem_types = set(
        'arrow', # performant, potentially large mem size 
        'df', # convenient, compatible 
        'df_lazy', # convenient, situational 
        'pickle' # convenient, situational 
        )


    ########## extract from storage to memory 
    
    # csv_to_df 
    def csv_to_df(file_name, search_path=None, col_spec=None):
        md = dict()
        if search_path:
            full_path = search_path + file_name
        else: 
            full_path = file_name
        md['src_name'] = file_name
        md['src_format'] = 'csv'
        md['obj'] = pd.read_csv(filepath_or_buffer=full_path, 
            delimiter=',', encoding='utf8', header=0, usecols=col_spec
            na_filter=False, cache_dates=True, 
        )
        md['obj_format'] = 'df'
        pipe = DataPipe(metadata=md)
        return pipe

    # csv_to_df_lazy 
    def csv_to_df_lazy(file_name, search_path=None, col_spec=None, chunk_config: int=5*10**4): 
        md = dict()
        if search_path:
            full_path = search_path + file_name
        else: 
            full_path = file_name
        
        n_lines = sum(1 for row in open(full_path, 'r', encoding='utf8'))
        if n_lines > (2 * chunk_config):
            n_chunk = n_lines // chunk_config + 1 # for logging/debug only
            iter_config = True
        else:
            n_chunk = 1 # for logging/debug only 
            chunk_config = None
            iter_config = False
        md['src_name'] = file_name
        md['src_format'] = 'csv'
        md['obj'] = pd.read_csv(filepath_or_buffer=full_path, 
            delimiter=',', encoding='utf-8', header=0, usecols=col_spec, 
            na_filter=False, cache_dates=True, 
            memory_map=True, iterator=iter_config, chunksize=chunk_config, 
        )
        md['obj_format'] = 'df_lazy'
        pipe = DataPipe(metadata=md)
        return pipe 

    # excel_to_arrow 
    # excel_to_df 
    # feather_to_arrow 
    # feather_to_df 
    # parquet_to_arrow 

    # parquet_to_df 
    def parquet_to_df(file_name, search_path=None, col_spec=None):
        md = dict()
        if search_path:
            full_path = search_path + file_name
        else: 
            full_path = file_name
        md['src_name'] = file_name
        md['src_format'] = 'parquet'
        md['obj'] = pd.read_parquet(filepath_or_buffer=full_path, 
            engine='auto', # currently tries pyarrow by default
            columns=col_spec, use_nullable_dtypes=True
        )
        md['obj_format'] = 'df'
        pipe = DataPipe(metadata=md)
        return pipe

    # sql_to_arrow 
    # sql_to_df 


    ########## swap in-memory 

    # arrow_to_df 
    # df_to_arrow 
    # df_to_pickle 
    # pickle_to_arrow 

    
    ########## load from memory to storage 
    
    # arrow_to_feather
    # arrow_to_parquet 
    # arrow_to_sql 
    # df_to_csv 
    # df_to_parquet 
    # df_to_sql 

