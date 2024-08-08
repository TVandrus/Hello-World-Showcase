"""
Related to solving the halting problem for arbitrary Turing machines
There are some machines/programs that run for exceedingly long times, but empirically found not to be ininite

These very-low-complexity setups that define very long sequences of computations are a prime candidate to test for performance optimizations
"""


"""
Turing machine program: 
Given a current State, and Value read from the Record:
logical behaviour to advance defined as
Value to write, Direction to advance, and new State
"""
program_bb4 = Dict( # 4-state BB
    :A=>Dict(0=>Dict(:w=>1, :d=>:R, :s=>:B),
        1=>Dict(:w=>1, :d=>:L, :s=>:B)
    ),
    :B=>Dict(0=>Dict(:w=>1, :d=>:L, :s=>:A),
        1=>Dict(:w=>0, :d=>:L, :s=>:C)
    ),
    :C=>Dict(0=>Dict(:w=>1, :d=>:R, :s=>:H),
        1=>Dict(:w=>1, :d=>:L, :s=>:D)
    ),
    :D=>Dict(0=>Dict(:w=>1, :d=>:R, :s=>:D),
        1=>Dict(:w=>0, :d=>:R, :s=>:A)
    ),
    :H=>nothing # halts in 107 steps 
)

program_bb5 = Dict( # 5-state BB, 47,176,870 steps
    :A=>Dict(0=>Dict(:w=>1, :d=>:R, :s=>:B),
        1=>Dict(:w=>1, :d=>:L, :s=>:C)
    ),
    :B=>Dict(0=>Dict(:w=>1, :d=>:R, :s=>:C),
        1=>Dict(:w=>1, :d=>:R, :s=>:B)
    ),
    :C=>Dict(0=>Dict(:w=>1, :d=>:R, :s=>:D),
        1=>Dict(:w=>0, :d=>:L, :s=>:E)
    ),
    :D=>Dict(0=>Dict(:w=>1, :d=>:L, :s=>:A),
        1=>Dict(:w=>1, :d=>:L, :s=>:D)
    ),
    :E=>Dict(0=>Dict(:w=>1, :d=>:R, :s=>:H),
        1=>Dict(:w=>0, :d=>:L, :s=>:A)
    ),
    :H=>nothing
)


program = program_bb5
record_tape::Vector{Integer} = [0];
state = :A;
i = 1;
step_count = 0;

@time while state != :H
    # read
    value = record_tape[i]
    p = program[state][value]
    
    # write
    record_tape[i] = p[:w]
    state = p[:s]
    
    # move along record tape 
    move = p[:d]
    if move == :L
        if i == 1
            pushfirst!(record_tape, 0)
        else
            i = i - 1
        end
    elseif move == :R
        i = i + 1
        if i > length(record_tape)
            push!(record_tape, 0)
        end
    end
    #@assert i > 0 "lower/left bound fail"
    step_count += 1
end
@info "Halted!\n\tin $step_count steps"


# performance step 1: make it a function
function run_busy_beaver(program)
    record_tape = [0];
    state = :A;
    i = 1;
    step_count = 0;

    while state != :H
        # read
        value = record_tape[i]
        p = program[state][value]
        
        # write
        record_tape[i] = p[:w]
        state = p[:s]
        
        # move along record tape 
        move = p[:d]
        if move == :L
            if i == 1
                pushfirst!(record_tape, 0)
            else
                i = i - 1
            end
        elseif move == :R
            i = i + 1
            if i > length(record_tape)
                push!(record_tape, 0)
            end
        end
        #@assert i > 0 "lower/left bound fail"
        step_count += 1
    end
    return "Halted!\n\tin $step_count steps"
end
@time run_busy_beaver(program_bb5)


# step 2: sizehint?
function run_busy_beaver_2(program::Dict{Symbol})
    record_tape = [0];
    state = :A;
    i = 1;
    step_count = 0;
    sizehint!(record_tape, 4000)
    while state != :H
        # read
        value = record_tape[i]
        p = program[state][value]
        
        # write
        record_tape[i] = p[:w]
        state = p[:s]
        
        # move along record tape 
        move = p[:d]
        if move == :L
            if i == 1
                pushfirst!(record_tape, 0)
            else
                i = i - 1
            end
        elseif move == :R
            i = i + 1
            if i > length(record_tape)
                push!(record_tape, 0)
            end
        end
        #@assert i > 0 "lower/left bound fail"
        step_count += 1
    end
    return "Halted!\n\tin $step_count steps"
end
@time run_busy_beaver_2(program_bb5)


