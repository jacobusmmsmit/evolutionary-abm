using Test

@testset "extinctions" begin
    using Agents
    using Distributions
    using StatsBase
    include("../src/evolutionary_model.jl");
    include("../src/helper_functions.jl");

    # Can it handle a single type going extinct?
    @test begin 
        model1 = evolutionary_model(;
            num_sitters=0,
            num_identifiers=1,
            num_cheaters=1,
            hatch_utility=5.0,
            egg_cost=1,
            identify_cost=1,
            eggs_laid=1,
            p_identify=1,
        )
        model_step!(model1) isa Any
    end
    # Can it handle multiple types going extinct?
    @test begin model2 = evolutionary_model(;
                    num_sitters=0,
                    num_identifiers=0,
                    num_cheaters=3,
                    hatch_utility=5.0,
                    egg_cost=1,
                    identify_cost=1,
                    eggs_laid=1,
                    p_identify=1,)
        run!(model2, agent_step!, model_step!, 10) isa Any
    end
end;