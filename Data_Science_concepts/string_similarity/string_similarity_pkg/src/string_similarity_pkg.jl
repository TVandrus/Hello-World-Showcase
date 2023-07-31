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
