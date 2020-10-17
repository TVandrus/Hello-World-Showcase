# creature-evolution.py
# Pythonic port of the original C by u/Ante13
# teach an AI to play a simple game (Neural Network trained via Evolutionary algorithm)

#import this
import os
import sys
import time
import numpy as np
import matplotlib.pyplot as plt

# start of creature-evolution setup
simulation = dict(iterations=5, watch_gen=1, max_gen=100)
world_param = dict(rows=22, cols=42, rock=80, food=90, creature=50)
world = np.empty((world_param['rows'], world_param['cols']), str)
symbol = dict(rock='#', food='.', creature='C', weak='w', empty=' ')

# columns=['alive','energy','action','y','x','age','fitness']
# matrix of integers to track creature state
creatures = np.zeros((world_param['creature'], 7), int)

eyesight = 6
objects = (symbol['empty'], symbol['rock'], symbol['food'], symbol['creature'], symbol['weak'])
nnet = dict(n_input=35,  # 8 dir * 4 obj + ener, mem1 + bias
            n_hidden1=8, # 7 + bias
            n_hidden2=6, # 5 + bias
            n_output=6)  # idle, up, down, left, right, memory
bias = dict(input=1, 
            hidden1=1, 
            hidden2=1)

mutation = dict(survivors=int(world_param['creature'] / 5),
                chance_sm=0.10, max_amt_sm=0.50, chance_lg=0.01)
if world_param['creature'] % mutation['survivors'] != 0: 
    print('survivors not a factor of # of creatures')
    sys.exit()

def init_world():
    # generate empty world with borders
    world[:, :] = symbol['empty']
    world[(0, -1), :] = symbol['rock']
    world[:, (0, -1)] = symbol['rock']
    
    # populate the world with rocks, food, creatures
    locations = np.random.choice(a=(world_param['rows'] - 2) * (world_param['cols'] - 2),
                                    size=sum([world_param.get(k) for k in ['creature','food','rock']]), replace=False)
    for l in range(len(locations)):
        r = (locations[l]-1) // (world_param['cols']-2) + 1
        c = (locations[l]-1) % (world_param['cols']-2) + 1
        if l < world_param['creature']:
            world[r, c] = symbol['creature']
            creatures[l, 3] = r
            creatures[l, 4] = c
        elif l < world_param['creature'] + world_param['food']:
            world[r, c] = symbol['food']
        else:
            world[r, c] = symbol['rock']

    # initialise creatures
    creatures[:,1] = np.random.choice(range(65, 86), size=world_param['creature'], replace=True)
    creatures[:,0] = True
    # end init_world()


def look(critter):
    row, col = (critter[3], critter[4])
    # given a critter's position, check the straight sightlines
    # return inputs for 4 directions, 4 object types
    sight = np.zeros(16)
    up = world[row-1 : row-eyesight, col]
    down = world[row+1 : row+eyesight, col]
    left = world[row, col-1 : col-eyesight]
    right = world[row, col+1 : col+eyesight]

    for i, dir in enumerate([up, down, left, right]):
        for j, sqr in enumerate(dir):
            if sqr == objects[0]:
                continue # look past empty spaces
            elif sqr == objects[1]:
                sight[i*4 + 0] = 1 - 2*(j/eyesight)
                break
            elif sqr == objects[2]:
                sight[i*4 + 1] = 1 - 2*(j/eyesight)
                break
            elif sqr == objects[3]:
                sight[i*4 + 2] = 1 - 2*(j/eyesight)
                break
            elif sqr == objects[4]:
                sight[i*4 + 3] = 1 - 2*(j/eyesight)
                break
            else:
                print('wtf is that?')

    return sight


def move(critter):
    # given current location and intended action
    # update the state of the creature and the world

    if not critter[0]:
        # dead critters don't move
        return critter
        #sys.exit()

    cost = 1
    if critter[2] == 0:  
        pass
    else:
        y_dest = int(critter[3])
        x_dest = int(critter[4])
        
        if critter[2] == 1:  # up
            y_dest -= 1
        elif critter[2] == 2:  # down
            y_dest += 1
        elif critter[2] == 3:  # left
            x_dest -= 1
        elif critter[2] == 4:  # right
            x_dest += 1

        if world[y_dest, x_dest] in (symbol['empty'], symbol['food']):
            world[critter[3], critter[4]] = symbol['empty']
            if world[y_dest, x_dest] == symbol['food']:
                cost = -25
                critter[6] += 1 # explicitly reward eating food
            critter[3] = y_dest
            critter[4] = x_dest
        else:  # rock, creature, or weak creature
            cost = 2
            critter[6] -= 1 # explicitly punish walking into things
            # no change in position or world
    
    critter[1] -= cost

    if critter[1] > 50:
        world[critter[3], critter[4]] = symbol['creature']
    elif critter[1] > 0:
        world[critter[3], critter[4]] = symbol['weak']
    else: # died
        critter[0] = False
        critter[5] = sim_age
        world[critter[3], critter[4]] = symbol['food']
    return critter
    # end move()


# initialise the simulation
sim_start = time.perf_counter()
sim_CPU_start = time.process_time()

#np.random.seed(1337)

sim_age_highest = 0
hist_fitness = np.zeros(simulation['max_gen'], dtype=int)

# allocate structure of the neural network layers
nn_input = np.zeros((world_param['creature'], nnet['n_input']), float)
nn_hidden1 = np.zeros((world_param['creature'], nnet['n_hidden1']), float)
nn_hidden2 = np.zeros((world_param['creature'], nnet['n_hidden2']), float)
nn_output = np.zeros((world_param['creature'], nnet['n_output']), float)

# initialise bias terms
nn_input[:,-1] = bias['input']
nn_hidden1[:,-1] = bias['hidden1']
nn_hidden2[:,-1] = bias['hidden2']

# initialise first generation with random weights, floats from -1 to 1
w_input_hidden1 = 2 * np.random.ranf(size=(world_param['creature'], 
                                                nnet['n_input'], 
                                                nnet['n_hidden1']-1)) - 1
w_hidden1_hidden2 = 2 * np.random.ranf(size=(world_param['creature'], 
                                                nnet['n_hidden1'], 
                                                nnet['n_hidden2']-1)) - 1
w_hidden2_output = 2 * np.random.ranf(size=(world_param['creature'], 
                                                nnet['n_hidden2'], 
                                                nnet['n_output'])) - 1


# start main simulation process
for generation in range(simulation['max_gen']):
    # record peak fitness of previous generation
    # before resetting fitness on every generation start
    gen_start = time.perf_counter()
    creatures[:,6] = 0

    # creatures live n-lives per generation
    for iteration in range(simulation['iterations']):
        
        # generate new world populated with creatures, food, rocks
        #  and initialise creatures
        init_world()
        living_creatures = world_param['creature']
        sim_age = 1

        while living_creatures > 0:
            # simulate a step, update all creatures
            
            # calculate NN inputs to decide action
            nn_input[:,:-3] = 0
            # memory
            #nn_input[:, 34] = nn_input[:, 33] # mem 2 takes the value of mem 1
            nn_input[:, 33] = nn_output[:, -1] # mem 1 is output from last time
            # energy
            nn_input[:, 32] = (creatures[:,1] / 50) - 1
            
            # eyesight; inputs 0-31
            # straight lines of sight
            nn_input[:, 0:16] = np.apply_along_axis(func1d=look, axis=1, arr=creatures)
            # diagonal lines of sight
            # (not implemented)

            # neural net inference
            #print('got to NN')
            #####
            nn_hidden1[:,:-1] = 0
            nn_hidden2[:,:-1] = 0
            nn_output[:,:] = 0

            if not np.isfinite(w_input_hidden1).all():
                print(w_input_hidden1)
                sys.exit()
            elif not np.isfinite(w_hidden1_hidden2).all():
                print(w_hidden1_hidden2)
                sys.exit()
            elif not np.isfinite(w_hidden2_output).all():
                print(w_hidden2_output)
                sys.exit()


            nn_hidden1[:,:-1] = np.einsum('ci,cih->ch', nn_input, w_input_hidden1)
            if not np.isfinite(nn_hidden1).all():
                print(np.round_(nn_hidden1, 2))
                sys.exit()
            nn_hidden1[nn_hidden1 < 0] = 0 # RELU activation
            nn_hidden2[:,:-1] = np.einsum('ch,chj->cj', nn_hidden1, w_hidden1_hidden2)
            if not np.isfinite(nn_hidden2).all():
                print(np.round_(nn_hidden2, 2))
                sys.exit()
            nn_hidden2[nn_hidden2 < 0] = 0 # RELU activation
            nn_output[:,:] = np.einsum('cj,cjo->co', nn_hidden2, w_hidden2_output)
            # decide action from NN output
            creatures[:,2] = np.argmax(nn_output, axis=1)

            #creatures.action = 0 # OVERWHELMINGLY LAZY CREATURES for testing
            
            # determine resulting creature and world state
            #creatures = creatures.apply(func=move, axis=1) # pandas apply tries first function call twice -> side effects occur twice
            #for index, critter in creatures.iterrows(): creatures.loc[index] = move(critter) # pandas iterrows ... not fast enough
            creatures = np.apply_along_axis(func1d=move, axis=1, arr=creatures) # pure numpy, very fast
            #print('moved creatures, ',living_creatures)
            living_creatures = sum(creatures[:,0])
            sim_age += 1
            sim_age_highest = max(sim_age_highest, sim_age)

            # render world after a warm-up period
            if (simulation['max_gen']-1 - generation) < simulation['watch_gen']:
                os.system('cls')
                print('Gen:' + str(generation) + ' Iter:' + str(iteration) +
                      ' Age:' + str(sim_age) + ' Alive:' + str(living_creatures))
                np.savetxt(fname=sys.stdout, X=world, fmt='%c', delimiter=' ')
                #print(creatures)
                time.sleep(0.03)
            # end step update
        creatures[:,6] += creatures[:,5]
        # end iteration
    
    # iterations completed for the generation
    #print('got to GA')
    # Genetic modification algorithm
    #####
    # select indices of creatures by fitness (top 20%)
    hist_fitness[generation] = max(creatures[:,6]) / simulation['iterations']
    winners = np.argsort(a=creatures[:,6], axis=0, kind='quicksort')[-mutation['survivors']:]
    # next generation start as clones of the survivors
    w_input_hidden1 = np.tile(A=w_input_hidden1[winners,:,:], reps=(5,1,1))
    w_hidden1_hidden2 = np.tile(A=w_hidden1_hidden2[winners,:,:], reps=(5,1,1))
    w_hidden2_output = np.tile(A=w_hidden2_output[winners,:,:], reps=(5,1,1))
    # keep one set (surviviors) intact, generate mutations for the rest
    mut_ih1 = mutation['max_amt_sm'] * (-1 + 2 * np.random.ranf(
        size=(world_param['creature'] - mutation['survivors'],
                nnet['n_input'], nnet['n_hidden1']-1)))
    mut_h1h2 = mutation['max_amt_sm'] * (-1 + 2 * np.random.ranf(
        size=(world_param['creature'] - mutation['survivors'], 
                nnet['n_hidden1'], nnet['n_hidden2']-1)))
    mut_h2o = mutation['max_amt_sm'] * (-1 + 2 * np.random.ranf(
        size=(world_param['creature'] - mutation['survivors'], 
                nnet['n_hidden2'], nnet['n_output'])))
    # generate mutation activations (probabilistic)
    act_ih1 = mutation['chance_sm'] > np.random.ranf(
        size=(world_param['creature'] - mutation['survivors'],
                nnet['n_input'], nnet['n_hidden1']-1))#.astype(float)
    act_h1h2 = mutation['chance_sm'] > np.random.ranf(
        size=(world_param['creature'] - mutation['survivors'], 
                nnet['n_hidden1'], nnet['n_hidden2']-1))#.astype(float)
    act_h2o = mutation['chance_sm'] > np.random.ranf(
        size=(world_param['creature'] - mutation['survivors'], 
                nnet['n_hidden2'], nnet['n_output']))#.astype(float)
    # apply mutations to new clones where activated
    w_input_hidden1[mutation['survivors']:, :, :] += mut_ih1 * act_ih1
    w_hidden1_hidden2[mutation['survivors']:, :, :] += mut_h1h2 * act_h1h2
    w_hidden2_output[mutation['survivors']:, :, :] += mut_h2o * act_h2o
    #####
    
    if generation % 10 == 0:
        print('Generation', generation, 'completed in', format(time.perf_counter() - gen_start,'.2f'))

# all generations completed
print('Simulation completed in', format(time.perf_counter() - sim_start, '.2f'), 
'\nCPU time:', format(time.process_time() - sim_CPU_start, '.2f'))

# plot progression
print(hist_fitness)

plt.plot(hist_fitness)
plt.show()
