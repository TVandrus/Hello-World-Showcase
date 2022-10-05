
// another example implementation of the original
// https://stackoverflow.com/questions/19123506/jaro-winkler-distance-algorithm-in-c-sharp/19165108//19165108

/*
Custom string fuzzy matching on a scale of [0, 1]
0 => no similarity, 1 => exact match
Loosely based on Jaro similarity: https://en.wikipedia.org/wiki/Jaro–Winkler_distance
Empirically, random/independent strings ~0.40 on average, similar strings >0.85
*/

fn main() {
    let s1_default: &str = "1313-123 Westcourt Place N2L 1B3";
    let s2_default: &str = "Unit 1313 123 Westcourt Pl. N2L1B3";
    let strip_default: Vec<&str> = vec![" "];
    let keep_case_default: bool = false;
    let ignore_short_default: u64 = 4;
    let verbose_default: bool = false; 
    string_compare(s1_default, s2_default, strip_default, keep_case_default, ignore_short_default, verbose_default)
}

fn string_compare(s1: &str, s2: &str, strip: Vec<&str>, 
        keep_case: bool, ignore_short: u16, verbose: bool) -> f64 {
    // Pre-Processing
    // remove spaces by default, allows arbitrary strings to be stripped away
    let mut process_1: String = s1.to_string(); 
    let mut process_2: String = s2.to_string(); 
    if strip.len() > 0_usize {
        for s in strip.iter() {
            process_1 = process_1.replace(s, ""); 
            process_2 = process_2.replace(s, ""); 
            debug!(("{}\n{}", process_1, process_2); 
        }
    }
    if !keep_case {// case insensitive by default
        process_1 = process_1.to_uppercase();
        process_2 = process_2.to_uppercase();
    }

    let is_ordered: bool = process_1.len() >= process_2.len(); 
    // guarantee s1 is longest string
    let s1 = if is_ordered {&process_1} else {&process_2} ;
    let s2 = if is_ordered {&process_2} else {&process_1} ;
    let l1: u64 = s1.len(); 
    let l2: u64 = s2.len(); 

    if verbose {// display processed strings
        debug!(("{} - {}", l1, s1); 
        debug!(("{} - {}", l2, s2);  
    }

    // short circuit if above processing makes an exact match
    if s1 == s2 {
        if verbose {debug!(("exact match")};
        return 1 ;
    } 
    
    if (l2 == 0) || (l2 <= ignore_short) {
        // arbitrary decision that fuzzy matching of 'short' strings
        //   is not informative
        if verbose {debug!(("short string")}; 
        // already tested for exact matches
        return 0;
    }

    // matching-window size
    //   original uses (max length ÷ 2) - 1
    //mdist = (l1 ÷ 2) - 1
    //mdist = l1 ÷ 4 // bidirectional window needs to be smaller
    let mdist = f64::floor(f64::sqrt(l1 as f64)) as i64;
    if verbose {debug!("match dist - {mdist}")};
    
    // order-sensitive match index of each character such that
    //   (goose, pot) has only one match [2], [2] but
    //   (goose, oolong) has two matches [1,2], [2,3]
    m1: Vec<u64> = vec![];
    m2: Vec<u64> = vec![]; 
    // m1 needed only for debugging

    for i:u64 in 1..l1 {
        window_start:u64 = max(1, i-mdist)
        window_end::Int = min(l2, i+mdist)
        if window_start > l2 {
            break
        }
        for j::Int in setdiff(window_start:window_end, m2) {
            if s1[i] == s2[j] {
                push!(m1, i) 
                push!(m2, j)
                break
            }
        }            
    }
    if verbose
        @debug m1 
        @debug m2
    }

    matches::Int = length(m2)
    if verbose
        debug!(("matches - $matches")
    }

    if matches == 0
        return 0
    elseif matches == 1
        return round((1/l1 + 1/l2 + 1) / 3, digits=3)
    else
        transposes = sum([!isless(m2[k-1], m2[k]) for k in 2:matches])
        if verbose
            debug!(("transposes - $transposes")
        }
        return round((matches / l1 + matches / l2 +
                (matches - transposes) / matches ) / 3, digits=3)
    }    
}

/* basic scenario testing
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
*/
