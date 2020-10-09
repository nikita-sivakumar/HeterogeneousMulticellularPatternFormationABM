import nl4py
nl4py.startServer("NetLogo 6.0.4/")
nl4py.deleteAllHeadlessWorkspaces()
n = nl4py.newNetLogoHeadlessWorkspace()
n.openModel("Circuit_ABCD_Asymm_3.1_ParameterTuning.nlogo")

import numpy as np
parNames = n.getParamNames()
print(parNames)
parRanges = n.getParamRanges()
print(parRanges)

from deap import base
from deap import creator
from deap import tools
from deap import algorithms
creator.create("FitnessMin",base.Fitness,weights=(-1.0,))
creator.create("Individual",list,fitness = creator.FitnessMin)
toolbox = base.Toolbox()

import random
parInit = []
for pname, prange in zip(parNames, parRanges):
    pname = ''.join(filter(str.isalnum, str(pname)))
    if len(prange) == 3:
        toolbox.register(pname, random.randrange, \
            prange[0], prange[2], prange[1])
        parInit.append(eval("toolbox." + str(pname)))

toolbox.register("individual", tools.initCycle, creator.Individual,tuple(parInit))

from skimage.measure import label, regionprops, regionprops_table
import time
import pandas as pd
import numpy as np
print("i imported everything")

exp_metrics={"green_fract": 0.48224608,
                "red_fract": 0.370580433,
                "blue_fract": 0.274062823,
                "num_green_regions": 1,
                "avg_green_region_area": 0.58,
                "num_red_regions": 2.1,
                "avg_red_region_area": 0.24}
exp_metrics=pd.DataFrame.from_dict(exp_metrics,orient='index')

def simulate(workspace,names,values):
    workspace.command("reset-ticks")
    workspace.command("setup")
    check = workspace.report("count turtles")
    while(check == 0):
        workspace.command("setup")
        check = workspace.report("count turtles")
        
    for name, value in zip(names,values):
        cmd = 'set {0} {1}'.format(name, value)
        workspace.command(cmd)
    workspace.command("adjust-exp")
    # fitness = []
    # for i in range(10):
    workspace.command("repeat 100 [go]")
    results = [workspace.report("count turtles"),workspace.report("count turtles with [color = green]"),workspace.report("count turtles with [color = red]"),workspace.report("count turtles with [color = blue]"),workspace.report("count turtles with [color = gray]")]
    fit = 10
    if results[0] == 0:
        fit = [5]
        # fitness.append(fit)
        # print("this happened")
    else:
        img_green = np.zeros((17,17))
        img_red = np.zeros((17,17))
        for i in range(-8,9):
            for j in range(-8,9):
                cmd = 'count((bs-on patch {0} {1}) with [color = green])'.format(i, j)
                c = workspace.report(cmd)
                if c > 0:
                    img_green[i+8][j+8]=1
                cmd = 'count((as-on patch {0} {1}) with [color = red])'.format(i, j)
                c = workspace.report(cmd)
                if c > 0:
                    img_red[i+8][j+8]=1
        label_img_green = label(img_green,connectivity=1)
        green_props_test = regionprops(label_img_green)
        if len(green_props_test) > 0:
            green_props = regionprops_table(label_img_green, properties=('centroid','area'))
            green_props=pd.DataFrame(green_props)
            num_green_regions = sum(green_props.area > 2)
            if num_green_regions > 0:
                avg_green_region_area = sum(green_props.area[green_props.area > 2]) / num_green_regions
            else:
                avg_green_region_area = 0
        else:
            num_green_regions = 0
            avg_green_region_area = 0
        label_img_red = label(img_red,connectivity=1)
        red_props_test = regionprops(label_img_red)
        if len(red_props_test) > 0:
            red_props = regionprops_table(label_img_red, properties=('centroid','area'))
            red_props = pd.DataFrame(red_props)
            num_red_regions = sum(red_props.area > 2)
            if num_red_regions > 0:
                avg_red_region_area = sum(red_props.area[red_props.area > 2]) / num_red_regions
            else:
                avg_red_region_area = 0
        else:
            num_red_regions = 0
            avg_red_region_area = 0
        output_metrics={"green_fract": results[1] / results[0],
                "red_fract": results[2] / results[0],
                "blue_fract": results[3] / results[0],
                "num_green_regions": num_green_regions,
                "avg_green_region_area": avg_green_region_area / results[0],
                "num_red_regions": num_red_regions,
                "avg_red_region_area": avg_red_region_area / results[0]}
        output_metrics=pd.DataFrame.from_dict(output_metrics,orient='index')
        fit=[((output_metrics[0]-exp_metrics[0]) ** 2).sum()]
        # fitness.append(fit)
    # ret = [np.mean(fitness)]
    ret = fit
    return tuple(ret)
    
toolbox.register("population", tools.initRepeat, list, toolbox.individual)
toolbox.register("mate", tools.cxTwoPoint)
lowerBounds = [row[0] for row in parRanges]
upperBounds = []
for row in parRanges:
    if len(row)==1:
        upb = row[0]
    else:
        upb = row[2]
    upperBounds.append(upb)
toolbox.register("mutate", tools.mutUniformInt, low = lowerBounds, up = upperBounds, indpb = 0.1)
toolbox.register("select", tools.selTournament, tournsize = 3)

nl4py.deleteAllHeadlessWorkspaces()
POP = 100
freeWorkspaces = []
for i in range(0, POP):
    n = nl4py.newNetLogoHeadlessWorkspace()
    n.openModel("Circuit_ABCD_Asymm_3.1_ParameterTuning.nlogo")
    freeWorkspaces.append(n)
print("i created multiple headless workspaces")


def evaluateABM(individual):
    n = freeWorkspaces[0]
    freeWorkspaces.remove(n)
    result = simulate(n,parNames,individual)
    freeWorkspaces.append(n)
    return result
toolbox.register("evaluate", evaluateABM)


import multiprocessing
from multiprocessing.pool import Pool
print("i'm here")
numCores = 16

from multiprocessing.pool import ThreadPool
pool = ThreadPool(numCores)
toolbox.register("map", pool.map)


def main(POP,GEN):
    random.seed(42)
    population = toolbox.population(n = POP)
    cur_gen = 0
    
    CXPB, MUTPB = 0.7, 0.2
    
    fitnesses = list(map(toolbox.evaluate,population))
    for ind, fit in zip(population, fitnesses):
        ind.fitness.values = fit
        
    fits = [ind.fitness.values[0] for ind in population]
    
    fitness_overtime = []
    best_ind_overtime = []
    
    while cur_gen < GEN:
        cur_gen = cur_gen + 1
        
        # Select the next generation individuals
        offspring = toolbox.select(population, len(population))
        # Clone the selected individuals
        offspring = list(map(toolbox.clone, offspring))
        
        for child1, child2 in zip(offspring[::2], offspring[1::2]):

            # cross two individuals with probability CXPB
            if random.random() < CXPB:
                toolbox.mate(child1, child2)

                # fitness values of the children
                # must be recalculated later
                del child1.fitness.values
                del child2.fitness.values

        for mutant in offspring:

            # mutate an individual with probability MUTPB
            if random.random() < MUTPB:
                toolbox.mutate(mutant)
                del mutant.fitness.values
                
        invalid_ind = [ind for ind in offspring if not ind.fitness.valid]
        fitnesses = map(toolbox.evaluate, invalid_ind)
        for ind, fit in zip(invalid_ind, fitnesses):
            ind.fitness.values = fit
            
        population[:] = offspring
        fits = [ind.fitness.values[0] for ind in population]
        
        print("-- Generation %i --" % cur_gen)
        min_fitness = np.min(fits)
        print("  Min %s" % min_fitness)
        print("  Mean %s" % np.mean(fits))
        best_ind = tools.selBest(population, 1)[0]
        
        fitness_overtime.append(min_fitness)
        best_ind_overtime.append(best_ind)
    return fitness_overtime, best_ind_overtime

print("population size:")
print(POP)
print("ngen:")
GEN = 100
print(GEN)

fitness_overtime, best_ind_overtime = main(POP,GEN)
print(fitness_overtime)
print(best_ind_overtime)


# stats = tools.Statistics(key = lambda ind: ind.fitness.values)
# stats.register("min", np.min)
# stats.register("mean", np.mean)
# hof = tools.HallOfFame(GEN)
# final_pop, log = algorithms.eaSimple(toolbox.population(n = POP), toolbox, cxpb = 0.7, mutpb = 0.2, ngen = GEN,stats = stats,halloffame = hof)

# print(hof)
# progress = [d["min"] for d in log]
# print(progress)

nl4py.deleteAllHeadlessWorkspaces()
nl4py.stopServer()





