
include("string_similarity.jl"); 
using Base.Threads 
using DataFrames 

"""
Flexible application of string_similarity to find a 'join' between two vectors of strings  
Brute-force scan/search, heavy compute required but scalable via parallel threads 

Parameters:  
v1, v2: column vectors of AbstractString  
max_only: will return only the top-ranked match(es) within the allowed range  
lower_bound, upper_bound: 
"""
function fuzzy_left_join(
    v1, v2; 
    max_only=true, lower_bound=0, upper_bound=1, 
    string_compare_args=NamedTuple())

    if length(v1) == 0 || length(v2) == 0
        @warn "no matching with zero-length vector"
        return [[v1; v2] [v1; v2] one.([v1; v2])]
    end

    match_fn = (s, v) -> fuzzy_match(s, v, max_only=max_only, lower_bound=lower_bound, upper_bound=upper_bound, string_compare_args=string_compare_args) 
    matches = [ [] for _ in 1:Threads.nthreads()]

    Threads.@threads for i in v1 
        push!(matches[Threads.threadid()], match_fn(i, v2))
    end
    results = reduce(vcat, reduce(vcat, matches, init=[]))
    return results
end 


function fuzzy_match(
    s, v; 
    max_only=true, lower_bound=0, upper_bound=1, 
    string_compare_args=NamedTuple()) 

    sc_strip = get(string_compare_args, :strip, [" "]) 
    sc_keep_case = get(string_compare_args, :keep_case, false) 
    sc_ignore_short = get(string_compare_args, :ignore_short, 4) 

    compare_fn = (s1, s2) -> string_compare(s1, s2, verbose=false, strip=sc_strip, keep_case=sc_keep_case, ignore_short=sc_ignore_short) 
    compared = [ [] for _ in 1:Threads.nthreads()]

    Threads.@threads for w in v 
        compare_val = compare_fn(s, w) 
        if lower_bound <= compare_val <= upper_bound 
            push!(compared[Threads.threadid()], [s w compare_val Threads.threadid()])
        end
    end
    results = reduce(vcat, compared, init=[]) 
    if max_only
        best = maximum(getindex.(results, 3))
        filter!(x->x[3]==best, results) 
    end
    return reduce(vcat, results) 
end


