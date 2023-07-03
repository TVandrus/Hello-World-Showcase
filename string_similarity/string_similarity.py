
# another example implementation of the original
# https://stackoverflow.com/questions/19123506/jaro-winkler-distance-algorithm-in-c-sharp/19165108#19165108

"""
Custom string fuzzy matching on a scale of [0, 1]
0 => no similarity, 1 => exact match
Loosely based on Jaro similarity: https://en.wikipedia.org/wiki/Jaro–Winkler_distance
Empirically, random/independent strings ~0.40 on average, similar strings >0.85
"""
import math

def string_compare(s1, s2, verbose=False, strip=[" "], keep_case=False, ignore_short=4):
    # Pre-Processing
    # remove spaces by default, allows arbitrary strings to be stripped away
    if len(strip) > 0:
        for s in strip:
            s1 = s1.replace(s, "")
            s2 = s2.replace(s, "")
    l1 = len(s1)
    l2 = len(s2)
    if l1 < l2: # guarantee s1 is longest string
        s1, s2 = s2, s1
        l1, l2 = l2, l1
    
    if not keep_case: # case insensitive by default
        s1, s2 = s1.upper(), s2.upper()
    
    if verbose: # display processed strings
        print(f"{l1} - {s1}")
        print(f"{l2} - {s2}")
    
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
    #   (goose, pot) has only one match [2], [2] but
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
    if verbose:
        print(m1) 
        print(m2)
    
    matches = len(m2)
    if verbose: 
        print(f"matches - {matches}")
    
    if matches == 0: 
        return 0
    elif matches == 1: 
        return round((1/l1 + 1/l2 + 1) / 3, 3)
    else: 
        transposes = sum([(m2[k-1] >= m2[k]) for k in range(1, matches)])
        if verbose:
            print(f"transposes - {transposes}")
        return round((matches / l1 + matches / l2 + (matches - transposes) / matches ) / 3, 3)

s1 = "1313-123 Westcourt Place N2L 1B3"
s2 = "Unit 1313 123 Westcourt Pl. N2L1B3"

string_compare(s1, s2, verbose=True)

"""
# basic scenario testing
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
"""
