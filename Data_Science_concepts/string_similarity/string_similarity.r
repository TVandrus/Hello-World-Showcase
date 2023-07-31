
# another example implementation of the original
# https://stackoverflow.com/questions/19123506/jaro-winkler-distance-algorithm-in-c-sharp/19165108#19165108

"""
Custom string fuzzy matching on a scale of [0, 1]
0 => no similarity, 1 => exact match
Loosely based on Jaro similarity: https://en.wikipedia.org/wiki/Jaro-Winkler_distance
Empirically, random/independent strings ~0.40 on average, similar strings >0.85
"""

require(stringr)

string_compare <- function(s1, s2, verbose=FALSE, strip=c(" "), keep_case=FALSE, ignore_short=4) {
    # Pre-Processing
    # remove spaces by default, allows arbitrary strings to be stripped away
    if (length(strip) > 0) {
        s1 <- str_replace_all(s1, strip, "") 
        s2 <- str_replace_all(s2, strip, "") 
    }
    l1 <- str_length(s1) 
    l2 <- str_length(s2) 
    if (l1 < l2) { # guarantee s1 is longest string
        swap <- list(s1, s2) 
        s1 <- swap[2] 
        s2 <- swap[1] 
        l1 <- str_length(s1) 
        l2 <- str_length(s2) 
    }
    if (!keep_case) { # case insensitive by default
        s1 <- str_to_upper(s1) 
        s2 <- str_to_upper(s2) 
    }
    if (verbose) { # display processed strings
        message(l1, " - ", s1)
        message(l2, " - ", s2)
    }
    
    if (s1 == s2) { # short circuit if above processing makes an exact match
        return (1) 
    }
    if ((l2 == 0) || (l2 <= ignore_short)) { # arbitrary decision that fuzzy matching of 'short' strings is not informative
        if (verbose) { 
            message("short string") 
        }
        # already tested for exact matches
        return (0)
    }

    # matching-window size
    #   original uses (max length ÷ 2) - 1
    #mdist = (l1 ÷ 2) - 1
    #mdist = l1 ÷ 4 # bidirectional window needs to be smaller
    mdist = floor(sqrt(l1))
    if (verbose) { 
        message("match dist - ", mdist) 
    }
    
    # order-sensitive match index of each character such that
    #   (goose, pot) has only one match [2], [2] but
    #   (goose, oolong) has two matches [1,2], [2,3]
    m1 <- c() # m1 needed only for debugging
    m2 <- c() 
    for (i in 1:l1) {
        window_start = max(1, i-mdist)
        window_end = min(l2, i+mdist)
        if (window_start > l2) { 
            break
        }
        for (j in setdiff(window_start:window_end, m2)) {
            if (substring(s1, i, i) == substring(s2, j, j)) {
                m1 <- c(m1, i) 
                m2 <- c(m2, j)
                break
            }
        }            
    }
    if (verbose) {
        message(m1) 
        message(m2) 
    }
    matches = length(m2)
    if (verbose) {
        message("matches - ", matches)
    }

    if (matches == 0) {
        return (0)
    }
    else if (matches == 1) {
        # the 'else' condition for the general case would return the same outcome 
        # but this short-circuit skips the logic for transposes
        return (round((1/l1 + 1/l2 + 1) / 3, digits=3))
    }
    else {
        transposes = 0
        for (k in 2:matches) {
            transposes = transposes + (m2[k-1] > m2[k])
        }
        if (verbose) { 
            message("transposes - ", transposes)
        }
        return (round(
            (matches / l1 + 
            matches / l2 +
            (matches - transposes) / matches ) / 3, digits=3))
    }    
}


s1 = "1313-123 Westcourt Place N2L 1B3"
s2 = "Unit 1313 123 Westcourt Pl. N2L1B3"
string_compare(s1, s2)
string_compare(s1, s2, verbose=TRUE) 
