# dependencies.jl
# updated v1.8.4 - 2023-01

#using Core
#using Base
#using Pkg # access from REPL via ']' 
#Pkg.add('package_name')
#Pkg.update('package_name')
#Pkg.rm('package_name')
# help via '?'


# essentials
using Base.Threads, Profiling
using Dates
using DataFrames, Pandas, CategoricalArrays 

# mathematics/statistics
using LinearAlgebra
using StatsBase, Statistics

# input/output
using DelimitedFiles, CSV
using Arrow, TOML

# graphics
using Plots 

# miscellaneous
using Pluto, PlutoUI
using PackageCompiler
using PyCall
