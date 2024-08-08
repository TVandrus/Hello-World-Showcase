# dependencies.jl
# updated v1.10.0 - 2024-07

#using Core
#using Base
#using Pkg # access from REPL via ']' 
#Pkg.add('package_name')
#Pkg.update('package_name')
#Pkg.rm('package_name')
# help via '?'


# essentials
using Base.Threads, BenchmarkTools, Profiling 
using DataFrames, CategoricalArrays 
using Dates, Unitful 

# mathematics/statistics
using StatsBase, Statistics 
using LinearAlgebra 

# input/output
using DelimitedFiles, CSV, Arrow, TOML 
using DuckDB, LibPQ 

# graphics
using Pluto, PlutoUI, Markdown, InteractiveUtils 
using ProgressMeter
using Plots, Plotly

# system 
using PackageCompiler 
using PyCall 
