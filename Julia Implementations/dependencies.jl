# dependencies.jl
# updated v1.7.2 - 2022-07

#using Core
#using Base
#using Pkg # access from REPL via ']' -> Ctrl+C
#Pkg.add('package_name')
#Pkg.update('package_name')
#Pkg.rm('package_name')
# help via '?'


# essentials
using Base.Threads
using Profiling
using Dates
using CategoricalArrays
using SparseArrays
using DataFrames

# mathematics/statistics
using LinearAlgebra
using StatsBase, Statistics


# input/output
using DelimitedFiles
using CSV
using TOML
using Arrow

# graphics
using Plots 


# miscellaneous
using Pluto
using PackageCompiler