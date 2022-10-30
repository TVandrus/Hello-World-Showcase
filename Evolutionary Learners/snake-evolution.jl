
# snake-evolution.jl
# teach an AI to play Snake (Neural Network trained via Evolutionary algorithm)

module SnakeEvolution
export run_simulation, sim_param, world_param, nnet, mutation

using DelimitedFiles
using Base.Threads
using CPUTime
using Plots


# structs and configurations 
# define scenario 
    #=
    TODO: parameterize feedback (values affecting fitness) here
    =#
    const sim_param = (max_gen=10_000, max_games=7, sneks=50, watch_gen=[1,2,5,9,10]*1000)
    const world_param = (rows=Int32(19), cols=Int32(19))
    const mutation = (prob_sm=0.30, max_amt_sm=1.0, prob_lg=0.25)
    const feedback = (
        survive=1, # survival necessary, but not sufficient 
        crash=-100, # non-survival severely penalized 
        fed=25, # primary objective (requires survival) 
        approach=1, # incentive to move toward food as default 
        avoid=0, # penalty for for not seeking food 
        idle_limit=50, 
        lazy=-300, # penalty for starving, survival without feeding is unproductive (ie chasing own tail infinitely)
        achieve=10, # offset lazy penalty for points collected
    )


# input model
    #=
    TODO: define different models for drop-in replacements
        absolute (up/down/left/right) vs relative directions (forward, turn left, turn right) 
    =#
    # up, right, down, left, relative position[r,c],
    #    food dist [+/-, +/-], dir [+/-, +/-], memdir1..N[+/-, +/-]
    const nnet_abs = (input=8,
                hidden1=45,
                hidden2=45,
                hidden3=45,
                output=4) # up, right, down, left

    const nnet_rel = (input=8,
                hidden1=45,
                hidden2=45,
                hidden3=45,
                output=3) # up, right, down, left

    const nnet = nnet_abs # current architecture to be used 

# convenient abstractions/shorthand notation 
    const symbol = (empty=' ', rock='#', food='.', head='$', body='@')
    const empty_world = [repeat([symbol.rock], 1, world_param.cols+2);
                        repeat([symbol.rock repeat([symbol.empty], 1, world_param.cols) symbol.rock], world_param.rows, 1);
                        repeat([symbol.rock], 1, world_param.cols+2)]

    const d = (up=Array{Int32}([-1 0]),
            right=Array{Int32}([0 1]),
            down=Array{Int32}([1 0]),
            left=Array{Int32}([0 -1]) )
    const R = Array{Int32}([0 1; -1 0]) # left rotation

# data structures used for the simulation 
    mutable struct State
        food::Matrix{Int32}
        head::Matrix{Int32}
        body::Array{Matrix{Int32}, 1}
        time::Int32
        points::Int32
        fitness::Int32
        crash::Bool
        dir ::Matrix{Int32}
        mem1::Matrix{Int32}
        mem2::Matrix{Int32}
        mem3::Matrix{Int32}
    end
    # initialise snek at centre, random food location
    State() = State(#[rand(1:world_param.rows) rand(1:world_param.cols)],
                    [div(world_param.rows, 2)+2 div(world_param.cols, 2)+2],
                    [div(world_param.rows, 2) div(world_param.cols, 2)],
                    [[div(world_param.rows, 2) div(world_param.cols, 2)]],
                    0, 0, 0, false, 
                    d.up, [0 0], [0 0], [0 0]
    )

    """
    abstraction for neural net layers/architecture
    """
    struct Brain
        w_input_hidden1::Matrix{Float32}
        w_hidden1_hidden2::Matrix{Float32}
        w_hidden2_hidden3::Matrix{Float32}
        w_hidden3_output::Matrix{Float32}
    end
    Brain() = Brain(
        1 .- 2 .* rand(Float32, nnet.input, nnet.hidden1),
        1 .- 2 .* rand(Float32, nnet.hidden1, nnet.hidden2),
        1 .- 2 .* rand(Float32, nnet.hidden2, nnet.hidden3),
        1 .- 2 .* rand(Float32, nnet.hidden3, nnet.output),
    )
    function Base.display(b::Brain)::Nothing
        println(typeof(b))
        println(size(b.w_input_hidden1))
        println(size(b.w_hidden1_hidden2))
        println(size(b.w_hidden2_hidden3))
        println(size(b.w_hidden3_output))
        return nothing
    end
    function Base.display(ab::Array{Brain, 1})::Nothing
        display.(ab)
    end

    struct Report
        record::Array{Float64, 2}
        plot1
        plot2
        plot3
        winners::Array{Brain, 1}
    end
    function Base.display(x::Report)::Nothing
        println(typeof(x))
        println("Total Execution time: ", round(sum(x.record[:,8]), digits=2))
        display(x.record[Array([1:5; end-5:end]), :])
        display(plot(x.plot2, x.plot3, layout=(2,1)))
        display(x.winners[1])
    end

# core simulation components/logic 
"""
Display a game State via terminal
"""
function draw(state::State)::Nothing

    world = copy(empty_world)
    world[state.food[1]+1, state.food[2]+1] = symbol.food
    for s in state.body
        world[s[1]+1, s[2]+1] = symbol.body
    end
    world[state.head[1]+1, state.head[2]+1] = symbol.head
    
    # print world and stats
    print(repeat('\n', 5))
    println("running ...")
    println("Time: ", state.time, "  Points: ", state.points)
    writedlm(stdout, world, ' ')
    sleep(0.06)
    return nothing
end

"""
Updates Direction based on nnet logic applied to State 
TODO: separate logic for different models (absolute vs relative)
"""
function think!(state::State, brain::Brain)::State
    # allocate model arrays
    nn_input = zeros(Float32, 1, nnet.input)
    nn_hidden1 = zeros(Float32, 1, nnet.hidden1)
    nn_hidden2 = zeros(Float32, 1, nnet.hidden2)
    nn_hidden3 = zeros(Float32, 1, nnet.hidden3)
    nn_output = zeros(Float32, 1, nnet.output)
    
    # fill in inputs
    # check adjacent squares: left, straight, and right
    #=
    for (i, adj) in enumerate([state.head+state.dir*R, state.head+state.dir, state.head-state.dir*R])
        if any([ any(adj .< 1), (adj[1] > world_param.rows), (adj[2] > world_param.cols), (adj in state.body) ])
            nn_input[i] = -1
        elseif adj == state.food
            nn_input[i] = 1
        else # empty space
            nn_input[i] = 0
        end
    end
    =#
    
    #=
    nn_input[9:12] = [state.head[1]/world_param.rows, 
                    state.head[2]/world_param.cols,
                    (state.food[1])/world_param.rows, 
                    (state.food[2])/world_param.cols]

    nn_input[9:10] = state.dir
    nn_input[11:12] = state.mem1
    nn_input[13:14] = state.mem2
    nn_input[15:16] = state.mem3
    
    state.mem3 = state.mem2
    state.mem2 = state.mem1
    state.mem1 = state.dir
    =#
    
    # fill in inputs
    for (i, adj) in enumerate([d.up, d.right, d.down, d.left])
        adj = state.head + adj
        if all([ all(adj .> 0), (adj[1] <= world_param.rows), (adj[2] <= world_param.cols), !(adj in state.body) ])
            nn_input[i] = 1 # safe to go
        end
    end
    
    fdir = state.head - state.food
    if fdir[1] > 0
        nn_input[5] = 1 # food is up
    elseif fdir[1] < 0
        nn_input[7] = 1 # food is down
    end

    if fdir[2] < 0
        nn_input[6] = 1 # food is right
    elseif fdir[2] > 0
        nn_input[8] = 1 # food is left
    end
    
    
    # calculate output
    nn_hidden1 = nn_input * brain.w_input_hidden1
    nn_hidden1[nn_hidden1 .< 0] .= 0
    nn_hidden2 = nn_hidden1 * brain.w_hidden1_hidden2
    nn_hidden2[nn_hidden2 .< 0] .= 0
    nn_hidden3 = nn_hidden2 * brain.w_hidden2_hidden3
    nn_hidden3[nn_hidden3 .< 0] .= 0
    nn_output = nn_hidden3 * brain.w_hidden3_output

    a = argmax(vec(nn_output))
    #a = rand([1,2,3,4]) #TESTING w RANDOM BRAIN

    # update state direction accordingly
    if a == 1 # up
        state.dir = d.up
    elseif a == 2 # right
        state.dir = d.right
    elseif a == 3 # down
        state.dir = d.down
    elseif a == 4 # left
        state.dir = d.left
    else
        error("What are you trying to do?")
    end

    return state
end

"""
Executes action determined by think!(), and evaluates consequences
Produces a new State, including the reward calculation
"""
function move!(state::State)::State
    if state.crash
        error("Already crashed, cannot move")
    end
    # attempt to move in chosen direction
    state.head = state.head + state.dir
    # check target space
    state.crash = any( [ any(state.head .< 1), 
                    (state.head[1] > world_param.rows), 
                    (state.head[2] > world_param.cols), 
                    (state.head in state.body) ] )
    if state.crash
        state.fitness += feedback.crash
    else # didn't crash, move successful
        push!(state.body, state.head)
        state.fitness += feedback.survive 
        if state.head != state.food 
            popfirst!(state.body)
            # reward approaching food
            if sum(abs.(state.head - state.food)) < sum(abs.((state.head-state.dir)-state.food))
                state.fitness += feedback.approach
            elseif sum(abs.(state.head - state.food)) > sum(abs.((state.head-state.dir)-state.food))
                state.fitness += feedback.avoid
            end
        else # got food 
            state.points += 1 
            state.food = [rand(1:world_param.rows) rand(1:world_param.cols)]
            state.fitness += feedback.fed * state.points
        end
        state.time += 1
    end

    return state
end

"""
Run a game start to finish
Return outcome as raw data 
"""
function run_game(brain::Brain, watch::Bool)::Array{Int32, 1}
    state = State()
    if watch
        draw(state)
    end
    while ! state.crash 
        state = think!(state, brain)
        state = move!(state)
        if watch
            draw(state)
        end
        if state.time > (feedback.idle_limit * (state.points+1))
            # terminate infinite loops, allow successful sneks more time
            state.crash = true
            state.fitness += (feedback.lazy + feedback.achieve*state.points)
            if (feedback.lazy + feedback.achieve*state.points) > 0
                @debug("timed out with lazy penalty offset by score achieved")
            end
        end
    end

    return [state.time, state.points, state.fitness]
end

"""
Run all games for all sneks, then select and mutate
Return generational outcome and new generation
"""
function run_generation(n_games::Int64, n_sneks::Int64, brains::Array{Brain, 1}, watch::Bool)::Tuple{Array{Float64, 1}, Array{Brain, 1}}
    outcomes = zeros(Int32, n_sneks, 3)

    @threads for s in 1:n_sneks
        # play all games for a generation
        # return aggregate outcome
        iter_outcomes = zeros(Int32, 3, n_games) # time, points, fitness
        for g in 1:n_games
            iter_outcomes[:, g] = run_game(brains[s], watch && s==1 && g==1)
        end
        outcomes[s, :] = vec(sum(iter_outcomes, dims=2))
    end
    #display(outcomes)

    # selection and mutation
    # pick top performers by fitness, clone them 5x
    winners = sortperm(outcomes[:,3], rev=true)[1:div(n_sneks, 5)]
    
    #println(winners)
    
    clones = repeat(brains[winners], 5)
    tester = clones[length(winners)+1]
    # keep one set of survivors intact, generate mutations for the rest
    for c in length(winners)+1:n_sneks
        mut_ih1 = mutation.max_amt_sm .* (1 .- 2 .* rand(nnet.input, nnet.hidden1))
        mut_h1h2 = mutation.max_amt_sm .* (1 .- 2 .* rand(nnet.hidden1, nnet.hidden2))
        mut_h2h3 = mutation.max_amt_sm .* (1 .- 2 .* rand(nnet.hidden2, nnet.hidden3))
        mut_h3o = mutation.max_amt_sm .* (1 .- 2 .* rand(nnet.hidden3, nnet.output))
        # generate small mutation activations (probabilistic)
        act_ih1 = mutation.prob_sm .> rand(nnet.input, nnet.hidden1)
        act_h1h2 = mutation.prob_sm .> rand(nnet.hidden1, nnet.hidden2)
        act_h2h3 = mutation.prob_sm .> rand(nnet.hidden2, nnet.hidden3)
        act_h3o = mutation.prob_sm .> rand(nnet.hidden3, nnet.output)
        # apply small mutations to new clones where activated
        clones[c] = Brain(clones[c].w_input_hidden1 + mut_ih1 .* act_ih1,
            clones[c].w_hidden1_hidden2 + mut_h1h2 .* act_h1h2,
            clones[c].w_hidden2_hidden3 + mut_h2h3 .* act_h2h3,
            clones[c].w_hidden3_output + mut_h3o .* act_h3o )

        # major mutations
        mut_ih1 = 1 .- 2 * rand(nnet.input, nnet.hidden1)
        mut_h1h2 = 1 .- 2 * rand(nnet.hidden1, nnet.hidden2)
        mut_h2h3 = 1 .- 2 * rand(nnet.hidden2, nnet.hidden3)
        mut_h3o = 1 .- 2 * rand(nnet.hidden3, nnet.output)
        # generate major mutation activations (probabilistic)
        act_ih1 = mutation.prob_lg .> rand(nnet.input, nnet.hidden1)
        act_h1h2 = mutation.prob_lg .> rand(nnet.hidden1, nnet.hidden2)
        act_h2h3 = mutation.prob_lg .> rand(nnet.hidden2, nnet.hidden3)
        act_h3o = mutation.prob_lg .> rand(nnet.hidden3, nnet.output)
        # apply major mutations to new clones where activated
        clones[c] = Brain(clones[c].w_input_hidden1 .* (1 .- act_ih1) + (mut_ih1 .* act_ih1),
            clones[c].w_hidden1_hidden2 .* (1 .- act_h1h2) + (mut_h1h2 .* act_h1h2),
            clones[c].w_hidden2_hidden3 .* (1 .- act_h2h3) + (mut_h2h3 .* act_h2h3),
            clones[c].w_hidden3_output .* (1 .- act_h3o) + (mut_h3o .* act_h3o) )
    end
    if tester == clones[length(winners)+1]
        error("no mutation")
    end
    return ( [ maximum(outcomes[:, 1]) / n_games,
            sum(outcomes[:, 1]) / n_games / n_sneks,
            maximum(outcomes[:,2]) / n_games,
            sum(outcomes[:, 2]) / n_games / n_sneks,
            maximum(outcomes[:,3]) / n_games,
            sum(outcomes[:, 3]) / n_games / n_sneks ],
            clones)
end

"""
Run all generations
Track execution and learning progress over time, present summary of final learning outcomes 
"""
function run_simulation(n_generations=sim_param.max_gen, n_games=sim_param.max_games, n_sneks=sim_param.sneks, watch_gen=sim_param.watch_gen)
    brains = [Brain() for n in 1:n_sneks]
    
    # max time, avg time, max points, avg points, max fitness, avg fitness, generation execution time
    gen_record = zeros(Float64, n_generations, 8)
    gen_record[:, 1] = 1:n_generations

    for generation in 1:n_generations
        t = @elapsed gen_record[generation, 2:7], brains = run_generation(n_games, n_sneks, brains, (generation in watch_gen))
        gen_record[generation, 8] = t

        if generation % 50 == 0
            println("Generation ", generation, " completed in: ", round(gen_record[generation, 8], digits=4), 
                    "\tMax fitness: ", round(gen_record[generation, 6], digits=1),
                    "\tAvg fitness: ", round(gen_record[generation, 7], digits=1))
        end
    end
    
    samples = 1:Int64(max(1, floor(n_generations/500))):n_generations
    p1 = plot(gen_record[samples, 1], gen_record[samples, 2:3], seriestype=:scatter, xlim=:auto, ylim=[0,1000], title="Snek Time", label=["Max" "Avg"])
    p2 = plot(gen_record[samples, 1], gen_record[samples, 4:5], seriestype=:scatter, xlim=:auto, ylim=[0,20], title="Snek Points", label=["Max" "Avg"])
    p3 = plot(gen_record[samples, 1], gen_record[samples, 6:7], seriestype=:scatter, xlim=:auto, ylim=[-100,4000], title="Snek Fitness", label=["Max" "Avg"])

    #display(plot(p2, p3, layout=(2,1)))

    return Report(gen_record, p1, p2, p3, brains[1:5])
end

"""
Trivial usage to pre-compile and demonstrate function
"""
function test_run()
    return run_simulation(n_generations=2, n_games=1, n_sneks=5, watch_gen=[1])
end

end # module
