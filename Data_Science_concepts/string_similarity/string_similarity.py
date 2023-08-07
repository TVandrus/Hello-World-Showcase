# another example implementation of the original
# https://stackoverflow.com/questions/19123506/jaro-winkler-distance-algorithm-in-c-sharp/19165108#19165108
# translated from the original string_compare implemented in Julia

"""
Custom string fuzzy matching on a scale of [0, 1]
0 => no similarity, 1 => exact match
Loosely based on Jaro similarity: https://en.wikipedia.org/wiki/Jaro–Winkler_distance
Empirically, random/independent strings ~0.40 on average, similar strings >0.85
"""
import math

def string_compare(s1, s2, 
                   strip=[" "], keep_case=False, ignore_short=4, 
                   verbose=False): 
    """
    Custom string fuzzy matching on a scale of [0, 1], where 0 => no similarity and 1 => exact match; loosely based on Jaro similarity: https://en.wikipedia.org/wiki/Jaro-Winkler_distance

    \nParameters:
    \n`s1`, `s2`: input strings to compare for similarity
    \n`strip`: list of strings to be removed from the inputs, ie spaces or other non-informative characters, default removes spaces
    \n`keep_case`: default false to ignore letter-case differences
    \n`ignore_short`: default 4, upper bound on string length (after processing) where algorithm reverts to exact matching. This algorithm is designed for long, semi-structured strings (ie concatenated parts of a street address) and for 'short' strings even the most minimal difference (ie 'form' vs 'from') can reasonably be entirely different meanings
    \n`verbose`: default false, set to true to output additional diagnostic details from execution
    \n
    \nEmpirically, random/independent strings ~0.40 on average, similar strings >0.85
    \n
    \nThis custom algorithm first implemented by Thomas Vandrus in Julia in 2021-03
    """
    # Pre-Processing
    # remove spaces by default, allows arbitrary strings to be stripped away
    if len(strip) > 0:
        for s in strip:
            s1 = s1.replace(s, "")
            s2 = s2.replace(s, "")

    l1, l2 = len(s1), len(s2)
    if l1 < l2: # guarantee s1 is longest string
        s1, s2 = s2, s1
        l1, l2 = l2, l1
    
    if not keep_case: # case insensitive by default
        s1, s2 = s1.upper(), s2.upper()
    
    if verbose: # display processed strings
        print("\n\nprocessed strings:")
        print(f"{s1}")
        print(f"{s2}")
        print(f"processed lengths: {l1} and {l2}")
    
    # short circuit if above processing makes an exact match
    if s1 == s2:
        return 1
    
    if (l2 == 0) or (l2 <= ignore_short): 
        # arbitrary decision that fuzzy matching of 'short' strings
        #   is not informative
        if verbose: 
            print("short string")
        
        # already tested for exact matches
        return 0

    # matching-window size
    #   original uses (max length ÷ 2) - 1
    #mdist = (l1 ÷ 2) - 1
    #mdist = l1 ÷ 4 # bidirectional window needs to be smaller
    mdist = math.floor(math.sqrt(l1))
    if verbose:
        print(f"match dist - {mdist}")
    
    # order-sensitive match index of each character such that
    #   (goose, pot) has only one match [2], [2] and
    #   (goose, oolong) has two matches [1,2], [2,3]
    m1, m2 = [], []
    # m1 needed only for debugging
    for i in range(0, l1): 
        window_start = max(0, i-mdist)
        window_end = min(l2, i+mdist)
        if window_start > l2: 
            break

        for j in set(range(window_start, window_end)).difference(m2): 
            if s1[i] == s2[j]: 
                m1.append(i) 
                m2.append(j) 
                break

    matches = len(m2)
    if verbose:
        print(f"matches - {matches}")
        print(m1) 
        print(m2)

    if matches == 0: 
        return 0
    elif matches == 1: 
        # the 'else' condition for the general case would return the same outcome
        # but this short-circuit skips the logic for transposes
        return round((1/l1 + 1/l2 + 1) / 3, 3)
    else: 
        transposes = sum([(m2[k-1] >= m2[k]) for k in range(1, matches)])
        if verbose:
            print(f"transposes - {transposes}")
        
        return round(
            (matches / l1 + 
             matches / l2 + 
             (matches - transposes) / matches ) / 3
             , 3)


"""
# basic scenario testing
s1 = "martha"
s2 = "marhta"

s1 = "1313-123 Westcourt Place N2L 1B3"
s2 = "Unit 1313 123 Westcourt Pl. N2L1B3"

s1 = "123 Falconridge Cres Kitchener ON N2K1B3"
s2 = "123 Falconridge Crescent Kitchener ON N2K1B3"

string_compare(s1, s2, verbose=true) 
"""
