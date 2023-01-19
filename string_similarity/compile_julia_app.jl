
using Pkg, PackageCompiler

cd("string_similarity/") # path/to/Sample-Projects/string_similarity/

Pkg.generate("string_similarity_pkg")


########## define this file in /string_similarity/string_similarity_pkg/src/
module string_similarity_pkg 

include("../../string_similarity.jl") # defines string_compare function 

function julia_main()::Cint
    try
        @show string_compare(ARGS[1], ARGS[2]) 
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
        return 1
    end
    return 0
end

end # module string_similarity_pkg

########## 


# gathers julia runtime and any .jl scripts and their dependencies in a pre-compiled bundle
# results in a somewhat portable .exe that can be run on a machine without otherwise installing julia
# ~360 MB
create_app("string_similarity_pkg", "string_similarity_app", filter_stdlibs=true, force=true) 


cd "string_similarity/string_similarity_app/bin/"
.\"string_similarity_pkg.exe" "1313-123 Westcourt Place N2L 1B3" "Unit 1313 123 Westcourt Pl. N2L1B3" 


include("../../string_similarity.jl") # defines string_compare function 
s1 = "1313-123 Westcourt Place N2L 1B3"
s2 = "Unit 1313 123 Westcourt Pl. N2L1B3"
string_compare(s1, s2)
