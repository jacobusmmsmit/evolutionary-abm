using Distributed
using DataFrames

@everywhere using Agents

@everywhere include("evolutionary_model.jl")
@everywhere include("helper_functions.jl")

@everywhere num_each_type = 10
@everywhere num_steps = 20
@everywhere replicates = 2

@everywhere multirun_model = evolutionary_model(;
    num_sitters=num_each_type,
    num_identifiers=num_each_type,
    num_cheaters=num_each_type,
    hatch_utility=4,
    egg_cost=2,
    identify_cost=1,
    eggs_laid=1,
    p_identify=1,
    p_mutation=0.1
)

@everywhere sitters(a) = typeof(a) == Sitter
@everywhere identifiers(a) = typeof(a) == Identifier
@everywhere cheaters(a) = typeof(a) == Cheater
@everywhere adata = [(sitters, count), (identifiers, count), (cheaters, count)]

data, _ = run!(multirun_model, agent_step!, model_step!, num_steps; adata=adata, replicates=replicates, parallel=true);

average_n_of_type(x) = mean(x) / (num_each_type * 3)

data |>
  df -> filter(row -> row.step == num_steps, df) |>
  df -> combine(df,
          :count_sitters =>  average_n_of_type  => :sitter ,
          :count_identifiers =>  average_n_of_type => :identifiers ,
          :count_cheaters =>  average_n_of_type => :cheaters ,
          )