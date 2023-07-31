/*
User-defined SQL function to use as the comparison operator for fuzzy joins on text fields
Developed on Postgres 15 (2023)

Custom string fuzzy matching on a scale of [0, 1]
0 => no similarity, 1 => exact match
Loosely based on Jaro similarity: https://en.wikipedia.org/wiki/Jaro-Winkler_distance
*/

/*
select *
from table_a as a
left join table_b as b 
    on string_similarity(a.text_field, b.text_field) >= 0.9
*/

CREATE OR REPLACE FUNCTION string_similarity(
    text_a text
    , text_b text
    , strip_chars text DEFAULT E' \t\n' -- use escaped string for special character escape sequences
    , keep_case bool default false  -- case-insensitive by default
    , min_length int DEFAULT 4 
    ) RETURNS text -- text for debug, output is a decimal
as $fn_body$ 
    << preprocess >> 
    declare 
        s1 text; 
        s2 text; 
        l1 int; 
        l2 int; 
        result real; 
    begin 
        text_a := translate(text_a, strip_chars); 
        text_b := translate(text_b, strip_chars); 
        if not keep_case then 
            text_a := upper(text_a); 
            text_b := upper(text_b); 
        end if; 
        if s1 = s2 then 
            --short circuit if above processing makes an exact match
            return 1.0;
        end if;
        if length(text_a) >= length(text_b) then 
            -- guarantee s1 is longest string 
            s1 := text_a;
            l1 := length(text_a); 
            s2 := text_b; 
            l2 := length(text_b); 
        else 
            s1 := text_b;
            l1 := length(text_b); 
            s2 := text_a; 
            l2 := length(text_a); 
        end if; 
        if not (l1 > min_length and l2 > min_length) then 
            -- arbitrary decision that fuzzy matching of 'short' strings is not informative, revert to simple matching
            -- ...already tested for exact matches
                return 0.0; 
            end if
            return result;
        end if; 
        
        << fuzzy >> -- block for inexact comparison logic 
        declare 
            mdist int; 
            m int array; 
            window_start int; 
            window_end int; 
        begin 
            mdist := floor(sqrt(preprocess.l1)); 
            for i in 1..preprocess.l1 loop
                window_start := greatest(1, i - mdist)
                window_end := least(preprocess.l2, i + mdist)
                if window_start > preprocess.l2 then 
                    exit; 
                end if; 
                
                foreach j in setdiff(window_start:window_end, m) loop 
                    if substring(preprocess.s1, i, 1) = substring(preprocess.s2, j, 1) then 
                        m := m || i;
                        exit; 
                    end if; 
                end loop; 
            end loop; 


            return round(
                (matches / l1 + 
                matches / l2 +
                (matches - transposes) / matches ) / 3, digits=3)
        end; 

        return 'Debug output: %', result; 
    end; 
$fn_body$ 
    LANGUAGE plpgsql -- syntax specific to server-side Procedural Language for PostgreSQL  
    IMMUTABLE 
    PARALLEL SAFE 
    RETURNS NULL ON NULL INPUT 
; 
