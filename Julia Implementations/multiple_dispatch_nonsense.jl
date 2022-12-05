# multiple_dispatch_nonsense.jl
"""
    JuliaCon 2019 | The Unreasonable Effectiveness of Multiple Dispatch | Stefan Karpinski
        https://www.youtube.com/watch?v=kc9HwsxE1OY

    Problem:
        To what degree does your design allow you to:
            + extend the data model
            + extend the set of possible operations
        While minimizing any instances of:
            - modifying existing code
            - code repitition
            - unhandled runtime error types

        --Mads Torgersen, "The Expression Problem Revisited"
"""

##################################################
# original Point

    """
        abstract type does not have structure
        does not have concrete data type representation
        does not have any behaviours in the definition
    """
    abstract type AbstractPoint <: Any end

    """
        Point is a subset/instance of AbstractPoint, and can be materialized  
        Valid instances are only restricted by abstract Number type, concrete structure still ambiguous  
        No behaviours baked in at the time of definition, beyond implicit constructor  
    """
    struct Point <: AbstractPoint
        x::Number
        y::Number
    end

    """
        Generic function to return an immutable struct 
        as the same type as given
        with one specified field modified, if present
    """
    function transform(x::T, field::Symbol, op::Function) where T <: AbstractPoint
        fns = fieldnames(T)
        if field in fns
            args = []
            for f in fns
                if f === field
                    push!(args, op(getfield(x, f)))
                else
                    push!(args, getfield(x, f))
                end
            end
            return T(args...)
        else
            return x::T
        end
    end

    """
        Basic re-use of a function to reduce code repetition
        and provide a nicer interface for desired use cases
    """
    function move_up(p::AbstractPoint)
        return transform(p, :y, y->(y+1))
    end

    function move_left(p::AbstractPoint)
        return transform(p, :x, x->(x-1))
    end

    # concise interface to abstract some predicted use cases
    P1 = Point(5, 3.0)
    move_up(P1)

##################################################
# explicitly depends on above resources, and adds new extensions

    struct iPoint <: AbstractPoint
        x::Integer
        y::Integer
    end

    P2 = iPoint(7, 4)

    struct Point3D <: AbstractPoint
        x::Number
        y::Number
        z::Number
    end 

    P3 = Point3D(3.0, 5, 8)

    function move_away(p::AbstractPoint)
        return transform(p, :z, z->(z-1))
    end

    function move_diagonal(p::AbstractPoint, dim1::Symbol, dim2::Symbol, dist::Number)
        return transform(p, dim1, d->(d + dist)) |>
            px->(transform(px, dim2, d->(d + dist))) 
    end

    move_diagonal(P2, :x, :y, -2)
    move_away(P3)

    # simple "inheritance", further code re-use
    # apply original functionality to structures that were unknown
    move_up(P2)
    move_up(P3)


    # well-behaved/'reasonable' result when applying new functionality to upstream data structures?
    # reverse-inheritance? (smart dispatch of appropriate generic)
    # if it makes logical sense, often it "just works" as expected
    move_away(P1)
    move_diagonal(P1, :x, :y, 1)

##################################################
# more complex/convoluted extension

    struct iPoint3D <: AbstractPoint
        x::Integer
        y::Integer
        z::Integer
    end

    P4 = iPoint3D(7, 1, 4)

    struct TimePoint <: AbstractPoint
        x::Number
        y::Number
        t::Number
    end

    P5 = TimePoint(-3, 2, 0)

    function Base.:+(a::P, b::P) where P <: AbstractPoint
        args = []
        for field in fieldnames(P)
            push!(args, +(getfield(a, field), getfield(b, field)))
        end
        return P(args...)
    end

    function Base.:*(a::P, b::P) where P <: AbstractPoint
        args = []
        for field in fieldnames(P)
            push!(args, *(getfield(a, field), getfield(b, field)))
        end
        return P(args...)
    end

    function Base.:+(a::P, n::Number) where P <: AbstractPoint
        args = []
        for field in fieldnames(P)
            push!(args, +(getfield(a, field), n))
        end
        return P(args...)
    end

    function Base.:*(a::P, n::Number) where P <: AbstractPoint
        args = []
        for field in fieldnames(P)
            push!(args, *(getfield(a, field), n))
        end
        return P(args...)
    end

    function zero(x::P) where P <: AbstractPoint
        return P(zeros(Number, fieldcount(P))...)
    end

    """
    Would iPoint3D traditionally 'inherit' from Point? iPoint? Point3D?

    """


    struct nDimPoint <: AbstractPoint
        data::AbstractDict{Symbol, Number}
        nDimPoint(dims, vals) = length(dims) == length(vals) ? new(dims, vals) : error("number of dims does not match vals")
    end

    function transform(x::nDimPoint, field::Symbol, op::Function)
        fns = fieldnames(T)
        if field in fns
            args = []
            for f in fns
                if f === field
                    push!(args, op(getfield(x, f)))
                else
                    push!(args, getfield(x, f))
                end
            end
            return T(args...)
        else
            return x::T
        end
    end



##################################################
# feasible extension-space expands exponentially

    abstract type AbstractRegion <: Any end

    struct Line <: AbstractRegion 
        p1::AbstractPoint 
        p2::AbstractPoint 
    end

