
# creature-evolution.jl
# julia port of the python port of original C by u/Ante13
# teach an AI to play a simple game (Neural Network trained via Evolutionary algorithm)

module CreatureEvolution

export run_simulation, sim_param, world_param, mutation, nnet

using StatsBase
using DelimitedFiles
using Base.Threads
using CPUTime
using Plots

# setup global options
    const sim_param = (max_gen=400, max_iter=5, watch_gen=(0,))
    const world_param = (rows=22, cols=42, rocks=100, food=150, creatures=50)
    const symbol = (rock='#', food='.', creature='C', weak='w', empty=' ')

    const mutation = (survivors=Int64(world_param.creatures / 5),
                    prob_sm=0.10, max_amt_sm=0.50, prob_lg=0.02)
    const nnet = (input=20, # 4 dir * 4 obj + energy, memX, memY, bias
                hidden1=10, # 
                hidden2=8, # 
                output=5) # idle, up, down, left, right
    const bias = (input=1, hidden1=1, hidden2=1)

    # individual critter = [1 alive, 2 energy, 3 y, 4 x, 5 action, 6 memX, 7 memY, 8 age, 9 fitness]
    const self = (alive=1, energy=2, y=3, x=4, action=5, memX=6, memY=7, age=8, fitness=9)


# initialise world and creatures for an iteration
function init_world()::Tuple{Array{Char, 2}, Array{Int64, 2}}
    
    world = Array{Char}(undef, (world_param.rows, world_param.cols))
    creatures = zeros(Int64, world_param.creatures, 9)

    # generate empty world with borders
    world[:,:] .= symbol.empty
    world[[1,world_param.rows], :] .= symbol.rock
    world[:, [1,world_param.cols]] .= symbol.rock

    # spawn rocks, food, creatures randomly
    locations = sample(1:(world_param.rows-2)*(world_param.cols-2)-1,
                    sum([world_param.rocks, world_param.food, world_param.creatures]),
                    replace = false)
    for l in 1:length(locations)
        r = div((locations[l]), (world_param.cols-2)) + 2
        c = (locations[l]) % (world_param.cols-2) + 2
        if l <= world_param.creatures
            world[r, c] = symbol.creature
            creatures[l, 3:4] = [r, c]
        elseif l <= (world_param.creatures + world_param.food)
            world[r, c] = symbol.food
        else
            world[r, c] = symbol.rock
        end
    end

    # initialise creatures
    creatures[:, 1] .= 1
    creatures[:, 2] = sample(65:85, world_param.creatures, replace=true)

    #writedlm(stdout, world, ' ')

    return (world, creatures)
end


function look(world::Array{Char}, critter, vision=6)::Array{Float64, 1}
    # given a critter's position, check the straight sightlines
    # return inputs for 4 directions, 4 object types
    row, col = [critter[3], critter[4]]
    sight = zeros(16)
    up = world[(row-1):-1:max(1, row-vision), col]
    down = world[(row+1):min(row+vision, world_param.rows), col]
    left = world[row, (col-1):-1:max(1, col-vision)]
    right = world[row, (col+1):min(col+vision, world_param.cols)]

    for (i, dir) in enumerate([up, down, left, right])
        for (j, sqr) in enumerate(dir)
            if sqr == symbol.empty
                continue # look past empty spaces
            elseif sqr == symbol.rock
                sight[(i-1)*4 + 1] = 1 - 2*((j-1)/vision)
                break
            elseif sqr == symbol.food
                sight[(i-1)*4 + 2] = 1 - 2*((j-1)/vision)
                break
            elseif sqr == symbol.creature
                sight[(i-1)*4 + 3] = 1 - 2*((j-1)/vision)
                break
            elseif sqr == symbol.weak
                sight[(i-1)*4 + 4] = 1 - 2*((j-1)/vision)
                break
            else
                println("wtf is that?")
            end
        end
    end
    return sight
end


# update creatures and world state according to intended actions
function moveall(world::Array{Char}, creatures::Array{Int64})::Tuple{Array{Char, 2}, Array{Int64, 2}}

    for critter in eachrow(creatures)

        if critter[1] == 0
            # dead critters do not move
            continue
        else
        
            cost = 1
            if critter[5] == 0 # critter idles
                critter[6:7] = [0, 0]
            else # critter attempts to move
                y_dest = critter[3]
                x_dest = critter[4]

                # set target coordinates [row,col] and memory [x,y] based on chosen action
                if critter[5] == 1 # up
                    y_dest -= 1
                    critter[6:7] = [0, 1]
                elseif critter[5] == 2 # down
                    y_dest += 1
                    critter[6:7] = [0, -1]
                elseif critter[5] == 3 # left
                    x_dest -= 1
                    critter[6:7] = [1, 0]
                elseif critter[5] == 4 # right
                    x_dest += 1
                    critter[6:7] = [-1, 0]
                end

                if world[y_dest, x_dest] in [symbol.empty, symbol.food]
                    # move successful, update world and critter
                    world[critter[3], critter[4]] = symbol.empty
                    if world[y_dest, x_dest] == symbol.food
                        cost -= 25
                        critter[9] += 1 # direct fitness reward for eating food
                    end
                    critter[3] = y_dest
                    critter[4] = x_dest
                else # implicitly rock, creature, or weak creature
                    # move not successful, no change to world or critter position
                    cost = 2
                    critter[9] -= 1 # direct fitness penalty for walking into things
                end
            end

            critter[2] -= cost # update energy
            # set creature symbol according to energy
            if critter[2] > 30
                world[critter[3], critter[4]] = symbol.creature
            elseif critter[2] > 0
                world[critter[3], critter[4]] = symbol.weak
            else # died
                critter[1] = 0
                world[critter[3], critter[4]] = symbol.food
            end
        end
    end
    return (world, creatures)
end


# update creature and world state
function run_step(world::Array{Char}, creatures::Array{Int64}, brains)::Tuple{Array{Char, 2}, Array{Int64, 2}}
    # creatures ponder their existence
    nn_input=zeros(world_param.creatures, nnet.input)
    nn_hidden1=zeros(world_param.creatures, nnet.hidden1)
    nn_hidden2=zeros(world_param.creatures, nnet.hidden2)
    nn_output=zeros(world_param.creatures, nnet.output)

    # fill in inputs
    # look
    nn_input[:, 1:16] = mapslices(c->look(world, c), creatures, dims=2)
    nn_input[:, 17:19] = creatures[:, [2,6,7]]
    nn_input[:, 20] .= bias.input

    # think / calculate nnet output to get action
    nn_hidden1 = reshape(sum(nn_input .* brains.w_input_hidden1, dims=2), (world_param.creatures, nnet.hidden1))
    nn_hidden1[nn_hidden1 .< 0] .= 0
    nn_hidden2 = reshape(sum(nn_hidden1 .* brains.w_hidden1_hidden2, dims=2), (world_param.creatures, nnet.hidden2))
    nn_hidden2[nn_hidden2 .< 0] .= 0
    nn_output = reshape(sum(nn_hidden2 .* brains.w_hidden2_output, dims=2), (world_param.creatures, nnet.output))
    
    # select highest output as chosen action (0 to 4)
    a = argmax(nn_output, dims=2)
    creatures[:, 5] = [a[i][2] for i in 1:world_param.creatures] .- 1
    
    # short circuit w overwhelming laziness
    #creatures[:,5] .= 0

    # move based on action
    moveall(world, creatures)

    return (world, creatures)
end


# given previous creature state, run a lifetime of steps
function run_iteration(brains, watch::Bool)::Array{Int64, 1}
    # intialise world, creatures
    world, creatures = init_world()
    sim_age = 1
    living_creatures = sum(creatures[:, 1])

    # continue steps until all creatures dead
    while living_creatures > 0
        world, creatures = run_step(world, creatures, brains)
        # record age of death
        creatures[creatures[:,1] + creatures[:,8] .== 0, 8] .= sim_age
        sim_age += 1
        living_creatures = sum(creatures[:, 1])

        if watch
            # print world and stats
            print(repeat('\n', 40))
            println("sim age: ", sim_age)
            println("living creatures: ", living_creatures)
            println("running ...")
            writedlm(stdout, world, ' ')
            sleep(0.05)
        end
    end
    # return fitness as age
    return creatures[:, 8]
end


# given previous generation of creatures, provide performance stats and new generation
function run_generation(brains, n_iterations::Int64, watch::Bool)

    fitness = zeros(Int64, world_param.creatures)
    iterfit = zeros(Int64, (world_param.creatures, n_iterations))

    # run iterations, tracking fitness across lives
    # in parallel if not being watched
    if watch
        for iteration in 1:n_iterations
            iterfit[:, iteration] = run_iteration(brains, true)
        end
    else
        @threads for iteration in 1:n_iterations
            iterfit[:, iteration] = run_iteration(brains, false)
        end
    end
    
    fitness = vec(sum(iterfit, dims=2))

    # selection and mutation
    # pick top performers by fitness, clone them
    winners = sortperm(fitness, rev=true)[1:mutation.survivors]
    new_ih1 = repeat(brains.w_input_hidden1[winners,:,:], 5,1,1)
    new_h1h2 = repeat(brains.w_hidden1_hidden2[winners,:,:], 5,1,1)
    new_h2o = repeat(brains.w_hidden2_output[winners,:,:], 5,1,1)

    # keep one set of survivors intact, generate mutations for the rest
    mut_ih1 = mutation.max_amt_sm .* (1 .- 2 .* 
                rand(world_param.creatures - mutation.survivors, nnet.input, nnet.hidden1))
    mut_h1h2 = mutation.max_amt_sm .* (1 .- 2 .*
                rand(world_param.creatures - mutation.survivors, nnet.hidden1, nnet.hidden2))
    mut_h2o = mutation.max_amt_sm .* (1 .- 2 .*
                rand(world_param.creatures - mutation.survivors, nnet.hidden2, nnet.output))
    # generate small mutation activations (probabilistic)
    act_ih1 = mutation.prob_sm .> 
                rand(world_param.creatures - mutation.survivors, nnet.input, nnet.hidden1)
    act_h1h2 = mutation.prob_sm .>
                rand(world_param.creatures - mutation.survivors, nnet.hidden1, nnet.hidden2)
    act_h2o = mutation.prob_sm .>
                rand(world_param.creatures - mutation.survivors, nnet.hidden2, nnet.output)
    # apply small mutations to new clones where activated
    new_ih1[mutation.survivors+1:end, :, :] += mut_ih1 .* act_ih1
    new_h1h2[mutation.survivors+1:end, :, :] += mut_h1h2 .* act_h1h2
    new_h2o[mutation.survivors+1:end, :, :] += mut_h2o .* act_h2o

    # major mutations
    mut_ih1 = (1 .- 2 .* rand(world_param.creatures - mutation.survivors, nnet.input, nnet.hidden1))
    mut_h1h2 = (1 .- 2 .* rand(world_param.creatures - mutation.survivors, nnet.hidden1, nnet.hidden2))
    mut_h2o = (1 .- 2 .* rand(world_param.creatures - mutation.survivors, nnet.hidden2, nnet.output))
    # generate major mutation activations (probabilistic)
    act_ih1 = mutation.prob_lg .> 
                rand(world_param.creatures - mutation.survivors, nnet.input, nnet.hidden1)
    act_h1h2 = mutation.prob_lg .>
                rand(world_param.creatures - mutation.survivors, nnet.hidden1, nnet.hidden2)
    act_h2o = mutation.prob_lg .>
                rand(world_param.creatures - mutation.survivors, nnet.hidden2, nnet.output)
    # apply major mutations to new clones where activated
    new_ih1[mutation.survivors+1:end, :, :] = new_ih1[mutation.survivors+1:end, :, :] .* (1 .- act_ih1)
    new_h1h2[mutation.survivors+1:end, :, :] = new_h1h2[mutation.survivors+1:end, :, :] .* (1 .- act_h1h2)
    new_h2o[mutation.survivors+1:end, :, :] = new_h2o[mutation.survivors+1:end, :, :] .* (1 .- act_h2o)
    
    new_ih1[mutation.survivors+1:end, :, :] += mut_ih1 .* act_ih1
    new_h1h2[mutation.survivors+1:end, :, :] += mut_h1h2 .* act_h1h2
    new_h2o[mutation.survivors+1:end, :, :] += mut_h2o .* act_h2o
    
    brains = (w_input_hidden1 = new_ih1,
            w_hidden1_hidden2 = new_h1h2,
            w_hidden2_output = new_h2o)
    
    # supply max, mean age of creatures sampled from last iteration of generation
    #  and mutated logic
    return ([maximum(fitness)/n_iterations, 
            sum(fitness)/world_param.creatures/n_iterations], 
            brains)
end


# main simulation
function run_simulation(n_generations=sim_param.max_gen, n_iterations=sim_param.max_iter, watch_gen=sim_param.watch_gen)

    println((n_generations, n_iterations, watch_gen))
    println(world_param)

    if world_param.creatures % mutation.survivors != 0
        error("survivors not a factor of # of creatures")
        return nothing
    end
    # 1 generation, 2 max age, 3 mean age, 4 elapsed execution time
    gen_record = zeros(n_generations, 4)
    brains = ( # initialise structure of heritable logic
        w_input_hidden1 = 1 .- 2 .* rand(world_param.creatures, nnet.input, nnet.hidden1),
        w_hidden1_hidden2 = 1 .- 2 .* rand(world_param.creatures, nnet.hidden1, nnet.hidden2),
        w_hidden2_output = 1 .- 2 .* rand(world_param.creatures, nnet.hidden2, nnet.output)
        )
    for generation in 1:n_generations
        watch = false # by default, run simulation in background
        if generation in watch_gen
            watch = true # arbitrary generations can be visualised
        end
        gen_record[generation, 1] = generation
        t = @elapsed gen_record[generation, 2:3], brains = run_generation(brains, n_iterations, watch)
        gen_record[generation, 4] = t

        if generation % 25 == 0
            println("Generation ", generation, " completed in: ", gen_record[generation, 4])
        end
    end
    # print machine performance stats
    p1 = plot(gen_record[:, 1], gen_record[:,4])
    # print creature performance stats
    p2 = plot(gen_record[:, 1], gen_record[:, 2:3], 
        seriestype=:scatter, xlim=:auto, ylim=[0,500],
        title="Creature Fitness", label=["Max" "Avg"])

    # plot progress curve
    println((n_generations, n_iterations, watch_gen))
    println(world_param)
    display(p2)
    return (gen_record, p1, p2)
end

end # end module