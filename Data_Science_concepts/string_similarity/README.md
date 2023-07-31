# Overview & Commentary on string_similarity 

- the project started simply with a desire for better fuzzy matching of unstructured text, where off-the-shelf solutions didn't quite provide enough utility, but also the use case had some loose but highly informative assumptions that could allow for a better solution
- the eventual algorithm was non-trivial, but did not require any atomic operations that were overly specialized, and so the choice of programming language and details of implementation had flexibility to be influenced by other factors (convenience, readability, performance)

## Developing the Problem Statement
- the specific use case was matching of addresses from across multiple systems of clients on jointly-held accounts for the purpose of mailing  account-related documents (mandated by regulation to be sent)
- the baseline was that the joint parties had a financial relationship, so there were several scenarios where they would reasonably share the same residence and financial statements, and sending identical copies for both parties would not contribute to a good client experience. 
- similarly, there were several plausible scenarios where the joint parties would not live together, and so required that each receive the required documents at their provided mailing address
- in cases where the addresses were trivially 'equal' (ie the use of "=" operators in Excel or SQL returned True) the documents were de-duplicated. In cases where they could be determined to be separate addresses for mailing purposes, both addresses were mailed. The challenge is that there are a variety of cases where the addresses were not 'equal' in the trivial sense of the text, but could be determined by manual review to be the same place, occurring frequently enough to warrant hours of manual review on a routine basis.
- my goal was to develop an algorithm that could compare two addresses, and in cases where the text was not exactly equal, highlight the cases that a manual reviewer would consider to be 'practically the same' due to a typo or other transformation in a small number of characters, but also to confidently deprioritise addresses that a reviewer would 'know' are not the same geographical place

## Benchmark issues 
Some key factors to determine if a solution was valuable enough to warrant implementation and the resulting process change: 

- there is a certain level of ambiguitity that can only be resolved by a human review (ie to contact another department to investigate), which the algorithm is not intended to replace (extreme/perfect accuracy is not required in order to provide substantial value) 
- if there are cases of the same location being represented by two addresses that are sufficiently mangled to look different, the default response is to mail to both so regulatory obligations were met (failing to find true matches has a low penalty) 
- flagging two geographically different addresses as the same would be highly problematic, so all suspected (inexact) matches still qualify for manual review (incorrectly flagging too many false matches costs effort, which is the target to reduce) 
- small differences of one or two characters (omissions, transpositions, additions, random replacements) including punctuation/whitespace are the most common cause of true matches not having equal text, and are obvious with manual review ("Montreal" vs "Montréal"). 
    * These need to have a low penalty on similarity, in order to improve granularity over "=" methods.
- 'typos' (UniversITy vs UniversTIy) and alternate text (Ave. vs Avenue) tend to be localized (NOT UnivErsity_Ave._ vs Univrsity Avenue, which have the exact same Set of unique letters, and the same count of "E"s, and the same number of total characters) 
    * a means of "local" matching would be smarter than set-based measures (ie intersection-divided-by-union) 
    * some pre-processing to remove spaces, possibly some other punctuation characters would reduce "noisy" differences without sacrificing information that would determine if addresses are a true match
- working with addresses across different data systems meant that even though there were structured fields (Street#, Street Name, City, Postal Code), they were not necessarily the same fields in both, or even a standardized format for a field within or between systems (ie representing PO Boxes, or Apartment/Unit/Suite identifiers) and each field is relatively small compared to the size of a 'typo'
    * design the algorithm to work on all (available) fields of an address concatenated in a way to maximize similarity between sources; this avoids designing logic per-field, or concerns about which fields are available in the future, as long as the rough order/template can be similar for pairs being compared

## Design of string_compare

### Logic 

* Pre-processing strings
* Short-circuit for trivial cases 
* Localized comparisons for matching characters
* Evaluate for transposes among matches 
* Output calculation 


### Implementation in code


## Implementing in Different Languages

My goal was to take the core logic, which is non-trivial but something I know forwards and backwards, and develop idiomatic ports that lean into the strengths of each language. As such, the look and feel of the code or the finished product is expected to vary across the different implementations.

### Julia 

My personal all-time favourite language since starting to program in 2008 (started experimenting w Julia early 2020), and my go-to language for prototyping. 

Julia has a suitably high level of abstraction and is highly expressive so that it is not cumbersome to move beyond primitive operations; it has good performance (minimal overhead beyond the compute complexity of the core logic) when prototyping without a second thought, and excellent performance with a little optimization. It is dynamically-typed, yet also has the richest type system I've learned of (Rust now is a close second), and it naturally encourages functional-programming patterns along with syntax that should feel familiar for a wide variety of domains/other languages.

It is not my first choice to suggest to casual/novice programmers because while it imposes very little in order to get something running, it lacks many of the safeguards that are inherent in languages like Rust, and lacks the massive community knowledge base of Python. I would definitely recommend it as a second language for developing programmers, because it will reduce some of the friction of coding, while giving many opportunities to get yourself into/out of trouble (in terms of performance, logical errors). 

### VBA 


### PowerShell 


### Python 

My preferred language when I want to use code/APIs written by others, and code as little logic as possible by myself. A Swiss-Army Knife of languages, and recommended as a first programming language across most domains. 

### Rust 

The most imposing and intimidating language to start using since I was introduced to C, and also the most helpful compiler I have ever known which served as a friendly teacher to show me all the numerous mistakes I made when coding a first draft of the function. A suitable low-level language with the conventions of the modern programmer. Not recommended for beginners without a formal background in computer science, nor for anyone else who doesn't have to worry about getting their code 'Production-Ready' 

### R 


