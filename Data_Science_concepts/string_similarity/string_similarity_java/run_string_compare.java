package string_similarity_java;

public class run_string_compare {
    public static void main(String[] args) {
        String[] strip = {" "};
        System.out.println(StringSimilarity.string_compare("Test String", "Testingr", strip, false, 5, true));
    }
}
