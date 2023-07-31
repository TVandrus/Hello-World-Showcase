
# another example implementation of the original
# https://stackoverflow.com/questions/19123506/jaro-winkler-distance-algorithm-in-c-sharp/19165108#19165108

"""
Custom string fuzzy matching on a scale of [0, 1], where 0 => no similarity and 1 => exact match; loosely based on Jaro similarity: https://en.wikipedia.org/wiki/Jaro-Winkler_distance

Parameters:  
`s1`, `s2`: input strings to compare for similarity  
`strip`: array of strings to be removed from the inputs, ie spaces or other non-informative characters, default removes spaces  
`keep_case`: default false to ignore letter-case differences  
`ignore_short`: default 4, upper bound on string length (after processing) where algorithm reverts to exact matching. This algorithm is designed for long, semi-structured strings (ie concatenated parts of a street address) and for 'short' strings even the most minimal difference (ie 'form' vs 'from') can reasonably be entirely different meanings  
`verbose`: default false, set to true to output additional diagnostic details from execution  

Empirically, random/independent strings ~0.40 on average, similar strings >0.85

This custom algorithm first implemented by Thomas Vandrus in Julia in 2021-03
"""
function string_compare(s1::String, s2::String; 
                        strip::Array{String}=[" "],
                        keep_case::Bool=false, 
                        ignore_short::Int=4,
                        verbose::Bool=false
                        )::Float64
    """
    s1, s2: arbitrary text strings to be compared for degree of similarity  
    verbose: default False, whether to display info from intermediate calculations
    strip: array of strings to strip from the given text before comparison
    """
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
        @info "$l1 - $s1"
        @info "$l2 - $s2"
    end
    
    if isequal(s1, s2) # short circuit if above processing makes an exact match
        return 1
    end
    if (l2 == 0) || (l2 <= ignore_short) # arbitrary decision that fuzzy matching of 'short' strings is not informative
        if verbose 
            @info "short string"
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
        @info "match dist - $mdist"
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
        @info m1 
        @info m2
    end

    matches::Int = length(m2)
    if verbose
        @info "matches - $matches"
    end

    if matches == 0
        return 0
    elseif matches == 1
        # the 'else' condition for the general would return the same outcome
        # but this short-circuit skips the logic for transposes
        return round((1/l1 + 1/l2 + 1) / 3, digits=3)
    else
        transposes = sum([!isless(m2[k-1], m2[k]) for k in 2:matches])
        if verbose
            @info "transposes - $transposes"
        end
        return round(
            (matches / l1 + 
            matches / l2 +
            (matches - transposes) / matches ) / 3, digits=3)
    end    
end

# s1 = "1313-123 Westcourt Place N2L 1B3"
# s2 = "Unit 1313 123 Westcourt Pl. N2L1B3"
# string_compare(s1, s2)
# string_compare(s1, s2, verbose=true) 
