

# another example implementation of the original
# https://stackoverflow.com/questions/19123506/jaro-winkler-distance-algorithm-in-c-sharp/19165108#19165108

"""
Custom string fuzzy matching on a scale of [0, 1]
0 => no similarity, 1 => exact match
Loosely based on Jaro similarity: https://en.wikipedia.org/wiki/Jaro–Winkler_distance
Empirically, random/independent strings ~0.40 on average, similar strings >0.85
"""
function string_compare(s1::String, s2::String; verbose::Bool=false,
                        strip::Array{String}=[" "], keep_case::Bool=false, 
                        ignore_short::Int=4)::Float64

    # Pre-Processing
    # remove spaces by default, allows arbitrary strings to be stripped away
    if length(strip) > 0
        for s in strip
            s1, s2 = replace(s1, s => ""), replace(s2, s => "")
        end
    end
    l1::Int, l2::Int = length(s1), length(s2)
    if l1 < l2 # guarantee s1 is longest string
        s1, s2 = s2, s1
        l1, l2 = l2, l1
    end
    if !keep_case # case insensitive by default
        s1, s2 = uppercase(s1), uppercase(s2)
    end
    if verbose # display processed strings
        println("$l1 - $s1")
        println("$l2 - $s2")
    end

    # short circuit if above processing makes an exact match
    if isequal(s1, s2)
        return 1
    end
    
    if (l2 == 0) || (l2 <= ignore_short)
        # arbitrary decision that fuzzy matching of 'short' strings
        #   is not informative
        if verbose 
            println("short string")
        end
        # already tested for exact matches
        return 0
    end

    # matching-window size
    #   original uses (max length ÷ 2) - 1
    #mdist = (l1 ÷ 2) - 1
    #mdist = l1 ÷ 4 # bidirectional window needs to be smaller
    mdist::Int = floor(Int, sqrt(l1))
    if verbose
        println("match dist - $mdist")
    end
    
    # order-sensitive match index of each character such that
    #   (goose, pot) has only one match [2], [2] but
    #   (goose, oolong) has two matches [1,2], [2,3]
    m1::Array{Int}, m2::Array{Int} = [], []
    # m1 needed only for debugging

    for i::Int in 1:l1
        window_start::Int = max(1, i-mdist)
        window_end::Int = min(l2, i+mdist)
        if window_start > l2
            break
        end
        for j::Int in setdiff(window_start:window_end, m2)
            if s1[i] == s2[j]
                push!(m1, i) 
                push!(m2, j)
                break
            end
        end            
    end
    if verbose
        @debug m1 
        @debug m2
    end

    matches::Int = length(m2)
    if verbose
        println("matches - $matches")
    end

    if matches == 0
        return 0
    elseif matches == 1
        return round((1/l1 + 1/l2 + 1) / 3, digits=3)
    else
        transposes = sum([!isless(m2[k-1], m2[k]) for k in 2:matches])
        if verbose
            println("transposes - $transposes")
        end
        return round((matches / l1 + matches / l2 +
                (matches - transposes) / matches ) / 3, digits=3)
    end    
end


#= basic scenario testing
s1 = "martha"
s2 = "marhta"

s1 = "Mr. John Smith"
s2 = "John M Smith"

s1 = "Julie S Morin"
s2 = "Julie T Morin"

s1 = "1313-123 Westcourt Place N2L 1B3"
s2 = "Unit 1313 123 Westcourt Pl. N2L1B3"

s1 = "123 Falconridge Cres Kitchener ON N2K1B3"
s2 = "123 Falconridge Crescent Kitchener ON N2K1B3"

string_compare(s1, s2, verbose=true) 
=#

#= performance testing
using Random, StatsBase, Base.Threads

string_compare("test", "string", verbose=true)

n = 100000
l = 100
results = zeros(n)
@time begin
    @threads for i in 1:n
        results[i] = string_compare(randstring("abcdefghijklmnopqrstuvwxyz0123456789 ", l),
                                    randstring("abcdefghijklmnopqrstuvwxyz0123456789 ", l))
    end
end
summarystats(results)

# performance test: 100k comparisons of random 100-char strings
# original: 10s, 257M alloc, 15 GiB, 40% gc
# type annotated: 9s 150M alloc, 13 GiB, 40% gc
=#
