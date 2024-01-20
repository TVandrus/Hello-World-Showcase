package string_similarity_java;
import java.util.ArrayList;
import java.util.logging.*;

public class StringSimilarity {
    /*
    Custom string fuzzy matching on a scale of [0, 1], where 0 => no similarity and 1 => exact match; loosely based on Jaro similarity: https://en.wikipedia.org/wiki/Jaro-Winkler_distance

    Parameters:  
    `s1`, `s2`: input strings to compare for similarity  
    `strip`: array of strings to be removed from the inputs, ie spaces or other non-informative characters, default removes spaces  
    `keep_case`: default false to ignore letter-case differences  
    `ignore_short`: default 4, upper bound on string length (after processing) where algorithm reverts to exact matching. This algorithm is designed for long, semi-structured strings (ie concatenated parts of a street address) and for 'short' strings even the most minimal difference (ie 'form' vs 'from') can reasonably be entirely different meanings  
    `verbose`: default false, set to true to output additional diagnostic details from execution  

    Empirically, random/independent strings ~0.40 on average, similar strings >0.85
    This custom algorithm first implemented by Thomas Vandrus in Julia in 2021-03
    */

    public static Logger logger = Logger.getLogger(StringSimilarity.class.getName());

    public static float string_compare(
        String s1, String s2) {
        String[] strip = {" "};
        return string_compare(s1, s2, strip);
    }

    public static float string_compare(
        String s1, String s2, String[] strip) {
        return string_compare(s1, s2, strip, false);
    }

    public static float string_compare(
        String s1, String s2, String[] strip, Boolean keep_case) {
        return string_compare(s1, s2, strip, keep_case, 5);
    }

    public static float string_compare(
        String s1, String s2, String[] strip, Boolean keep_case, int ignore_short) {
        return string_compare(s1, s2, strip, keep_case, ignore_short, false);
    }

    public static float string_compare(
        String s1, String s2, String[] strip, Boolean keep_case, int ignore_short, Boolean verbose) {
        
        // Pre-Processing
        // remove spaces by default, allows arbitrary strings to be stripped away
        if (strip.length > 0) { 
            for (String s : strip) {
                s1 = s1.replace(s, ""); 
                s2 = s2.replace(s, ""); 
            }
        }
        if (s1.length() < s2.length()) { // guarantee s1 is longest string
            String temp = s1;
            s1 = s2;
            s2 = temp;
        }
        int l1 = s1.length();
        int l2 = s2.length();
        if (!keep_case) { // case insensitive by default
            s1 = s1.toUpperCase(); 
            s2 = s2.toUpperCase();
        }
        if (verbose) { // display processed strings
            logger.info("\n\nprocessed strings: ");
            logger.info(s1);
            logger.info(s2);
            logger.info("processed lengths: " + l1 + " and " + l2);
        }
        // short circuit if above processing makes an exact match
        if (s1.equals(s2)) { 
            return 1.0f;
        }
        if ((l2 == 0) || (l2 <= ignore_short)) { 
            // arbitrary decision that fuzzy matching of 'short' strings 
            //   is not informative
            if (verbose) { 
                logger.info("short string");
            }
            // already tested for exact matches
            return 0.0f;
        }

        // matching-window size
        //   original uses (max length ÷ 2) - 1
        //   bidirectional window needs to be smaller
        int mdist = (int) Math.floor(Math.sqrt((double) l1));
        if (verbose) {
            logger.info("match dist - " + mdist);
        }
        // order-sensitive match index of each character such that
        //   (goose, pot) has only one match [2], [2] but
        //   (goose, oolong) has two matches [1,2], [2,3]
        ArrayList<Integer> m1 = new ArrayList<Integer>(); // m1 needed only for debugging
        ArrayList<Integer> m2 = new ArrayList<Integer>();
        int window_start; 
        int window_end;

        for (int i = 0; i < l1; i++) {
            window_start = Math.max(0, i-mdist);
            window_end = Math.min(l2, i+mdist);
            if (window_start > l2) {
                break;
            }
            for (int j = window_start; j < window_end; j++) {
                if (!m2.contains(j) && s1.charAt(i) == s2.charAt(j)) {
                    m1.add(i); 
                    m2.add(j);
                    break;
                }
            }
        }
        int matches = m2.size();
        if (verbose) {
            logger.info("matches - " + matches);
            logger.info(m1.toString());
            logger.info(m2.toString());
        } 
        if (matches == 0) {
            return 0.0f;
        } 
        else if (matches == 1) {
            // the 'else' condition for the general case would return the same outcome
            // but this short-circuit skips the logic for transposes
            return (float)Math.round((1f/l1 + 1f/l2 + 1f) / 3f * Math.pow(10f,3f)) / (float)Math.pow(10f,3f);
        } 
        else {
            int transposes = 0; 
            for (int k = 1; k < matches; k++) {
                if (!(m2.get(k-1) < m2.get(k))) { transposes++;}
            }
            if (verbose) {
                logger.info("transposes - " + transposes);
            }
            return (float)Math.round( 
                ((float)matches / l1 + 
                 (float)matches / l2 +
                (float)(matches - transposes) / matches ) / 3f
                * Math.pow(10,3)) / (float)Math.pow(10,3);
        }
    }
}
