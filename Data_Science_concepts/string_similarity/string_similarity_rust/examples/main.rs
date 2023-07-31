
/*
cargo run --example main 
*/

/* basic scenario testing
s1 = "martha"
s2 = "marhta"

s1 = "Katherine"
s2 = "Kahterine"

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


fn main() {
    // illustrative test case 
    let s1_default: &str = "1313-123 Westcourt Place N2L 1B3";
    let s2_default: &str = "Unit 1313 123 Westcourt Pl. N2L1B3";
    let strip_default: Vec<&str> = vec![" "];
    let keep_case_default: bool = false;
    let ignore_short_default: u64 = 4;
    let verbose_default: bool = true; 
    println!("{}", string_similarity_rust::string_similarity::string_compare(s1_default, s2_default, strip_default, keep_case_default, ignore_short_default, verbose_default))
}
