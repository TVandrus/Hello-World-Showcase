##################################################
# PowerShell setup code 
# ensure PATH is properly initialised or refreshed to include both Python and Julia
'''
cls; $Env:Path = [System.Environment]::GetEnvironmentVariable("Path","User"); 
cls; python; 
'''
##################################################
# Python interface code 

import os 
os.environ['PYTHON_JULIACALL_THREADS'] = '3'

import juliacall
from juliacall import Main as jl
jl.Threads.nthreads()

j_cmd = """
Threads.@threads for i in 0:50
    print(Threads.threadid())
end
"""
jl.seval(j_cmd)


# Python vars
os.chdir("string_similarity")
x = "test string"
y = ("test string", "TeStStRiNg", "testing", "testering", "test sting", "test sing")
type(y)

# pass Python args as Julia args to Julia fns, evaluated in Julia Main namespace 
jl.include("string_fuzzy_join.jl") 
jl.fuzzy_match(x, y)
jl.fuzzy_left_join(y, y)


##################################################
# Julia native code 
'''
pwd()

#include("string_similarity.jl")
include("string_fuzzy_join.jl")

x = "test string"
y = ["test string", "TeStStRiNg", "testing", "testering", "test sting", "test sing"]

test_run = fuzzy_match(x, y)
test_run = fuzzy_match(x, y, max_only=false)
test_run = fuzzy_match(x, y, max_only=false, lower_bound=0.9)
test_run = fuzzy_match(x, y, max_only=false, lower_bound=0.9, upper_bound=0.9999)

df = fuzzy_left_join(y, y)
df = fuzzy_left_join(y, y, upper_bound=0.9999)
df = fuzzy_left_join(y, y, max_only=false)
df = fuzzy_left_join(y, y, upper_bound=0.9999)
df = fuzzy_left_join(y, y, upper_bound=0.9999)

'''
