using Agents
using DataFrames

include("evolutionary_model.jl")
include("helper_functions.jl")

num_each_type = 20
num_steps = 30
replicates = 1

multirun_model = evolutionary_model(;
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

sitters(a) = typeof(a) == Sitter
identifiers(a) = typeof(a) == Identifier
cheaters(a) = typeof(a) == Cheater
adata = [(sitters, count), (identifiers, count), (cheaters, count)]
data, _ = run!(multirun_model, agent_step!, model_step!, num_steps; adata=adata, replicates=replicates);

# How good on average is each strategy
average_n_of_type(x) = mean(x) / (num_each_type * 3)

data |>
  df -> filter(row -> row.step == num_steps, df) |>
  df -> combine(df,
          :count_sitters =>  average_n_of_type  => :sitter ,
          :count_identifiers =>  average_n_of_type => :identifiers ,
          :count_cheaters =>  average_n_of_type => :cheaters ,
          )