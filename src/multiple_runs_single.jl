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

total_agents = 40
num_reps = 150
models = [evo_model(total_agents, i, j) for i in 1:(total_agents - 1) for j in 1:total_agents - i - 1 for replicates in 1:num_reps]

# Functions to collect data
sitters(a) = typeof(a) == Sitter
identifiers(a) = typeof(a) == Identifier
cheaters(a) = typeof(a) == Cheater
adata = [(sitters, count), (identifiers, count), (cheaters, count)]

@benchmark adf, = ensemblerun!(models, agent_step!, model_step!, 1; adata)
