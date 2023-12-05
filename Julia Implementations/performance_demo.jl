
# https://forem.julialang.org/wikfeldt/a-brief-tour-of-julia-for-high-performance-computing-5deb
# toy example of a sufficiently compute-intensive problem to test performance and optimization options

# first tested on AMD Ryzen 7 7800X3D, Julia 1.9.3, Win11 2023Q4

using BenchmarkTools, Plots

# initialize scenario for computation 
M = 4096
N = 4096
u = zeros(M, N);
# set boundary conditions
u[1,:] = u[end,:] = u[:,1] = u[:,end] .= 10.0;
unew = copy(u);


"""
Two-dimensional discretized Laplace function  
Naive performance Baseline
"""
function lap2d!(u, unew)
    M, N = size(u)
    for j in 2:N-1
        for i in 2:M-1
            unew[i,j] = 0.25 * (u[i+1,j] + u[i-1,j] + u[i,j+1] + u[i,j-1])
        end 
    end
end
@btime lap2d!(u, unew)
# 12.2 ms default


@time for i in 1:1_000
    lap2d!(u, unew)
    # copy new computed field to old array
    u = copy(unew)
end
# 30 s per 1000 steps baseline
heatmap(u)


"""
Blatant disregard for Julia's column-major array structure  
Result: cache misses for every iteration 
"""
function lap2d!(u, unew)
    M, N = size(u)
    for i in 2:M-1
        for j in 2:N-1
            unew[i,j] = 0.25 * (u[i+1,j] + u[i-1,j] + u[i,j+1] + u[i,j-1])
        end 
    end
end
@btime lap2d!(u, unew)
# 272 ms, ~22x slower than default 



# standard Julia optimizations 

"""
Two-dimensional discretized Laplace function  
Skip bounds-checking
"""
function lap2d!(u, unew)
    M, N = size(u)
    for j in 2:N-1
        for i in 2:M-1
            @inbounds unew[i,j] = 0.25 * (u[i+1,j] + u[i-1,j] + u[i,j+1] + u[i,j-1])
        end 
    end
end
@btime lap2d!(u, unew)
# 8.5 ms, saves 30% over default


Threads.nthreads()
"""
Two-dimensional discretized Laplace function  
Naive Threaded outer loop
"""
function lap2d!(u, unew)
    M, N = size(u)
    Threads.@threads for j in 2:N-1
        for i in 2:M-1
            unew[i,j] = 0.25 * (u[i+1,j] + u[i-1,j] + u[i,j+1] + u[i,j-1])
        end 
    end
end
@btime lap2d!(u, unew)
# 4.8 ms , saves 60% over default

"""
Two-dimensional discretized Laplace function  
Double Threaded loops overwhelmed by overhead
"""
function lap2d!(u, unew)
    M, N = size(u)
    Threads.@threads for j in 2:N-1
        Threads.@threads for i in 2:M-1
            unew[i,j] = 0.25 * (u[i+1,j] + u[i-1,j] + u[i,j+1] + u[i,j-1])
        end 
    end
end
@btime lap2d!(u, unew)
# 10.8 ms , saves 12% over default


"""
Two-dimensional discretized Laplace function  
Standard Julia optimizations: threaded loops, no bounds check
"""
function lap2d!(u, unew)
    M, N = size(u)
    Threads.@threads for j in 2:N-1
        for i in 2:M-1
            @inbounds unew[i,j] = 0.25 * (u[i+1,j] + u[i-1,j] + u[i,j+1] + u[i,j-1])
        end 
    end
end
@btime lap2d!(u, unew)
# 4.4 ms, saves 64% over default


@time for i in 1:5_000
    lap2d!(u, unew)
    # copy new computed field to old array
    u = copy(unew)
end
# 22 s per 1000 steps
heatmap(u)


# HPC approaches
using SharedArrays, Distributed, AMDGPU

"""
Two-dimensional discretized Laplace function  
Allow compiler more leeway to find SIMD options, requires inbounds assumption 
"""
function lap2d!(u, unew)
    M, N = size(u)
    for j in 2:N-1
        @simd for i in 2:M-1
            @inbounds unew[i,j] = 0.25 * (u[i+1,j] + u[i-1,j] + u[i,j+1] + u[i,j-1])
        end 
    end
end
@btime lap2d!(u, unew)
# 8.6 ms 

# distributed workers will not be as fast as multithreading when only scaled on one machine


# GPU acceleration
AMDGPU.devices()
AMDGPU.device()

M = 4096
N = 4096
u = zeros(M, N);
# set boundary conditions
u[1,:] = u[end,:] = u[:,1] = u[:,end] .= 10.0;
unew = copy(u);

u_gpu = AMDGPU.ROCArray(u);
unew_gpu = copy(u_gpu);


"""
Two-dimensional discretized Laplace function  
Naive performance Baseline
"""
function lap2d!(u, unew)
    M, N = size(u)
    for j in 2:N-1
        for i in 2:M-1
            unew[i,j] = 0.25 * (u[i+1,j] + u[i-1,j] + u[i,j+1] + u[i,j-1])
        end 
    end
end
@btime lap2d!(u_gpu, unew_gpu)
# 12.2 ms default


"""
Two-dimensional discretized Laplace function  
GPU-ified
"""
@inbounds function lap2d_gpu!(u, unew)
    M, N = size(u)
    #j = threadIdx().y + (blockIdx().y - 1) * blockDim().y
    #i = threadIdx().x + (blockIdx().x - 1) * blockDim().x
    j = workitemIdx().y + (workgroupIdx().y - 1) * workgroupDim().y
    i = workitemIdx().x + (workgroupIdx().x - 1) * workgroupDim().x
    if i > 1 && i < N && j > 1 && j < M
        unew[i, j] = 0.25 * (u[i+1,j] + u[i-1,j] + u[i,j+1] + u[i,j-1])
    end
    return nothing
end
groupsize = 128
gridsize = cld(M*N, groupsize)
AMDGPU.@roc gridsize=gridsize groupsize=groupsize lap2d_gpu!(u_gpu, unew_gpu)
AMDGPU.synchronize()
# 12.2 ms default

AMDGPU.Device.workgroupDim()