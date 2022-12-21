// another example implementation of the original
// https://stackoverflow.com/questions/19123506/jaro-winkler-distance-algorithm-in-c-sharp/19165108//19165108

/*
Custom string fuzzy matching on a scale of [0, 1]
0 => no similarity, 1 => exact match
Loosely based on Jaro similarity: https://en.wikipedia.org/wiki/Jaro–Winkler_distance
Empirically, random/independent strings ~0.40 on average, similar strings >0.85
*/
pub mod string_similarity { 
    pub fn string_compare(s1: &str, s2: &str, strip: Vec<&str>, 
            keep_case: bool, ignore_short: u64, verbose: bool) -> f64 {
        // Pre-Processing
        // remove spaces by default, allows arbitrary strings to be stripped away
        let mut process_1 = s1.to_string(); 
        let mut process_2 = s2.to_string(); 
        if strip.len() > 0_usize {
            for s in strip.iter() {
                process_1 = process_1.replace(s, ""); 
                process_2 = process_2.replace(s, ""); 
                if verbose {dbg!(&process_1, &process_2); }
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
        let l1 = s1.len() as u64; 
        let l2 = s2.len() as u64; 
        if verbose {// display processed strings
            dbg!(l1, s1); 
            dbg!(l2, s2); 
        } 

        // short circuit if above processing makes an exact match
        if s1 == s2 {
            if verbose {dbg!("exact match"); }
            return 1_f64 ;
        } 
        if (l2 == 0) || (l2 <= ignore_short) {
            // arbitrary decision that fuzzy matching of 'short' strings
            //   is not informative
            if verbose {dbg!("short string"); } 
            // already tested for exact matches
            return 0_f64;
        } 

        // matching-window size
        //   original uses (max length ÷ 2) - 1
        //mdist = (l1 ÷ 2) - 1
        //mdist = l1 ÷ 4 // bidirectional window needs to be smaller
        let mdist = f64::floor(f64::sqrt(l1 as f64)) as u64;
        if verbose {dbg!(mdist); } 
        
        // order-sensitive match index of each character such that
        //   (goose, pot) has only one match [2], [2] but
        //   (goose, oolong) has two matches [1,2], [2,3]
        let mut m1: Vec<usize> = Vec::new(); 
        let mut m2: Vec<usize> = Vec::new(); 
        //let mut window_start = 0_usize; 
        //let mut window_end = mdist as usize; 

        for i in 0_u64..l1 {
            let window_start = i64::max(i as i64 - mdist as i64, 0_i64) as usize; 
            let window_end = i64::min(i as i64 + mdist as i64, l2 as i64) as usize; 
            if window_start > l2 as usize {
                break;
            }
            let mut window: Vec<usize> = (window_start..window_end).collect(); 
            window.retain(|x| !(m2.contains(x))); 
            for &j in window.iter() {  
                if &s1.chars().nth(i as usize).unwrap() == &s2.chars().nth(j as usize).unwrap() {
                    m1.push(i as usize);
                    m2.push(j as usize); 
                    //dbg!("matched {}", &s1.chars().nth(i as usize).unwrap()); 
                    break;
                }
            }
        }
        if verbose {dbg!(&m1, & m2); } 

        let n_matches = m2.len() as u64; 
        if verbose {dbg!(n_matches); } 
        if n_matches == 0 {
            return 0_f64; 
        } 
        else if n_matches == 1 { 
            // the 'else' condition for the general would return the same outcome
            // but this short-circuit skips the logic for transposes
            let similarity = (1_f64 / l1 as f64 + 1_f64 / l2 as f64 + 1_f64) / 3_f64; 
            return math::round::half_away_from_zero(similarity, 3); 
        } 
        else {
            let mut n_transposes = 0_f64; 
            for k in 1_usize..(n_matches as usize) {
                if m2[k-1] > m2[k] {n_transposes += 1_f64;} 
            }
            if verbose {dbg!(n_transposes); }
            let f_matches = n_matches as f64; 
            let similarity = (
                (f_matches / l1 as f64) + 
                (f_matches / l2 as f64) + 
                ((f_matches - n_transposes) / f_matches) ) / 3_f64; 
            return math::round::half_away_from_zero(similarity, 3); 
        } 
    } 
} 
