using Agents
using DataFrames
using BenchmarkTools

include("evolutionary_model.jl")
include("helper_functions.jl")

evo_model(total_agents, i, j) = evolutionary_model(;
    num_sitters=i,
    num_identifiers=j,
    num_cheaters=total_agents - i - j,
    hatch_utility=4.0,
    egg_cost=0.9,
    eggs_laid=1,
    identify_cost=0.9,
    p_identify=1,
    p_mutation=0
)

total_agents = 10
num_reps = 10
models = [
    evo_model(total_agents, i, j)
        for i in 2:(total_agents - 2)
            for j in 2:total_agents - i - 2
                for replicates in 1:num_reps
]

@benchmark adf, = ensemblerun!(models, agent_step!, model_step!, 1)
