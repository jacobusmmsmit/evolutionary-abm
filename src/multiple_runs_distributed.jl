using Distributed
using BenchmarkTools
addprocs(3)

@everywhere begin
    using DataFrames
    using Agents
    include("evolutionary_model.jl")
    include("helper_functions.jl")

    distributed_model(total_agents, i, j) = evolutionary_model(;
        num_sitters=i,
        num_identifiers=j,
        num_cheaters=total_agents - i - j,
        hatch_utility=4.0,
        egg_cost=0.9,
        eggs_laid=1,
        identify_cost=0.9,
        p_identify=1,
        p_mutation=0.05
    )

    total_agents = 10
    num_reps = 10
    models = [
        distributed_model(total_agents, i, j)
            for i in 1:(total_agents - 1)
                for j in 1:total_agents - i - 1
                    for replicates in 1:num_reps
    ]
end

dist_bench = @benchmark ensemblerun!(models, agent_step!, model_step!, 1; parallel=true)