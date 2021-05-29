using Agents
using DataFrames
using Plots
using ImageFiltering
using TernaryPlots
using Loess

include("evolutionary_model.jl")
include("helper_functions.jl")
include("analytic_functions.jl")

# Defining a closure of the ABM initialiser so each model is the same
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

# Calculates the sum of squares difference between simulated and expected utilities
function accuracy_of_abm(total_agents, num_reps, metric="ssq")
    models = [
        evo_model(total_agents, i, j)
            for i in 0:(total_agents)
                for j in 0:total_agents - i
                    for replicates in 1:num_reps
    ]

    type_util(model) = model.utilities
    type_count(model) = model.nag
    mdata = [type_util, type_count]

    a, b = ensemblerun!(models, agent_step!, model_step!, 1; mdata)

    filter!(:step => !=(0), b)
    select!(b, Not(:step))
    transform!(b, [:type_util, :type_count] => ByRow((a, b) -> a ./ b) => [:mean_sitter, :mean_identifier, :mean_cheater])
    transform!(b, :ensemble => (col -> (col .- 1) .÷ num_reps) => :ens_grp)
    select!(b, Not(:ensemble))

    for col in eachcol(b)
        replace!(col, NaN => 0)
    end
    g = groupby(b, :type_count)
    g = combine(g, [:mean_sitter, :mean_identifier, :mean_cheater] => ((x, y, z) -> (mean(x), mean(y), mean(z))) => :means)


    transform!(g, :type_count => ByRow(a -> E(4, 0.9, 0.9, a...)) => :exp_util)

    replace!.(g.exp_util, NaN => 0)

    if metric == "ssq"
        ssq(x, y) = sqrt(sum((x .- y).^2))
        return sum(combine(g, [:means, :exp_util] => ByRow(ssq) => :root_ssq).root_ssq)
    else
        return(g)
    end
end


# function performance_heatmap(plot_nagents, plot_nruns)
#     reshape([(n, m) for n in plot_nagents for m in plot_nruns], length(plot_nruns), :)
#     plot_accuracy = reshape([accuracy_of_abm(n, m) for n in plot_nagents for m in plot_nruns], length(plot_nruns), :)
#     plot_accuracy_smooth = imfilter(plot_accuracy, Kernel.gaussian(1))
#     heatmap(plot_nagents, plot_nruns, plot_accuracy_smooth)
# end

# performance_heatmap(12:2:16, 10:5:40)

vect_dist(x, y) = sqrt.((x .- y).^2)

spread = accuracy_of_abm(30, 10, "spread")
transform!(spread, [:means, :exp_util] => ByRow(vect_dist) => :vec_dist)
performance_by_type = [mean([spread.exp_util[i][j] > 0 ? spread.vec_dist[i][j] / spread.exp_util[i][j] : 0 for i in 1:length(spread.vec_dist)]) for j in 1:3]

begin 
    sum_vec = [0.0, 0.0, 0.0]
    for i in 1:20
        spread = accuracy_of_abm(30, i, "spread")
        transform!(spread, [:means, :exp_util] => ByRow(vect_dist) => :vec_dist)
        sum_vec = hcat(sum_vec, [mean([spread.exp_util[i][j] > 0 ? spread.vec_dist[i][j] / spread.exp_util[i][j] : 0 for i in 1:length(spread.vec_dist)]) for j in 1:3])
    end
end
plot(1:21, sum_vec')

transform(spread, :vec_dist => ByRow(sum))

function accuracy_of_abm2(i, j, k, N, num_reps=10)
    
    models = [evo_model((i + j + k) * N, i * N, j * N) for replicates in 1:num_reps]
    
    type_util(model) = model.utilities
    type_count(model) = model.nag
    mdata = [type_util, type_count]
    
    a, b = ensemblerun!(models, agent_step!, model_step!, 1; mdata)
    
    filter!(:step => !=(0), b)
    select!(b, Not(:step))
    transform!(b, [:type_util, :type_count] => ByRow((a, b) -> a ./ b) => [:mean_sitter, :mean_identifier, :mean_cheater])
    transform!(b, :ensemble => (col -> (col .- 1) .÷ num_reps) => :ens_grp)
    select!(b, Not(:ensemble))
    
    for col in eachcol(b)
        replace!(col, NaN => 0)
    end
    g = groupby(b, :type_count)
    g = combine(g, [:mean_sitter, :mean_identifier, :mean_cheater] => ((x, y, z) -> (mean(x), mean(y), mean(z))) => :means)
    
    
    transform!(g, :type_count => ByRow(a -> E(4, 0.9, 0.9, a...)) => :exp_util)
    
    replace!.(g.exp_util, NaN => 0)
    ssq(x, y) = sqrt(sum((x .- y).^2))
    sum(combine(g, [:means, :exp_util] => ByRow(ssq) => :root_ssq).root_ssq)
end



accuracy_of_abm2(0.5, 0.4, 0.1, 50, 20)
accuracy_of_abm2(pS, pI, pC) = accuracy_of_abm2(pS, pI, pC, 50, 20) # 50 = 1/0.02 = stepsize

ternary_heatmap((x, y) -> accuracy_of_abm2(cart2tern(x, y)...), stepsize=0.02)

begin
    xs = 5:1:50
    ys = accuracy_of_abm.(20, xs)
    model = loess(collect(xs), ys)
    us = range(extrema(xs)...; step=0.1)
    lys = Loess.predict(model, us)
end

p2 = plot(xs, ys, seriestype=:scatter, label="Datapoints", size=(550, 300))
plot!(us, lys, color=:black, lw=2, ls=:dash, label="Loess Smoothing")
plot!(
    # title="Accuracy to Theoretical Values (#Agents = 20)",
    xlabel="Number of Repetitions",
    ylabel="Accuracy (Sum of L2-norms)"
)
# savefig(p2, "accuracy_smaller.pdf")

## Analytic Replicator Dynamics
# Closures
dpS(pS, pI, pC) = dpS(4, 0.9, 0.9, pS, pI, pC)
dpI(pS, pI, pC) = dpI(4, 0.9, 0.9, pS, pI, pC)
dpC(pS, pI, pC) = dpC(4, 0.9, 0.9, pS, pI, pC)

logmod(x) = sign(x) * log(abs(x) + 1)
function arrow(coords, scale=1)
    startpoint = [coords...]
    dp_tern = [dpS(startpoint...), dpI(startpoint...), dpC(startpoint...)]
    tern2cart.([startpoint, startpoint + logmod.(logmod.(dp_tern)) / scale])
end

mag(ar) = sqrt((ar[1][1] - ar[2][1])^2 + (ar[1][2] - ar[2][2])^2)
function ternary_arrows(n)
    labels = (A = "Sitters", B =  "Identifiers", C =  "Cheaters")
    p = ternary_plot(size=(400, 400), labels=labels)
    for i in 1:(n), j in 1:(n - i - 1)
        ar = arrow([i / n, j / n, (n - i - j) / n], 100)
        plot!(p, [ar[1][1], ar[2][1]], [ar[1][2], ar[2][2]],
        arrow=true,
line_z=log(mag(ar) + 0.03),
        lw=4,
        colour=cgrad(:viridis))
    end
    return p
end

    plot_arrows_anal = ternary_arrows(30)
x, y = tern2cart(NE(4, 0.9, 0.9))
plot!(plot_arrows_anal, [x], [y], seriestype=:scatter, shape=:circle, color=:black, msize=7, msw=1, ma=1, msc=:black, msa=1)
## Simulated Replicator Dynamics

function accuracy_of_abm3(total_agents, num_reps, metric="ssq")
    models = [
        evo_model(total_agents, i, j)
            for i in 1:total_agents - 1
                for j in 1:total_agents - i - 1
                    for replicates in 1:num_reps
    ]

    type_count_end(model) = collect(map(agent_type -> get_total_count(model, agent_type), [Sitter, Identifier, Cheater]))
    type_count(model) = model.nag
    mdata = [type_count, type_count_end]

    a, b = ensemblerun!(models, agent_step!, model_step!, 1; mdata)

    filter!(:step => !=(0), b)
    select!(b, Not(:step))
    transform!(b, :type_count_end => ByRow(x -> x[1]) => :mean_sitter)
    transform!(b, :type_count_end => ByRow(x -> x[2]) => :mean_identifier)
    transform!(b, :type_count_end => ByRow(x -> x[3]) => :mean_cheater)
    select!(b, Not(:ensemble))

    g = groupby(b, :type_count)
    combine(g, [:mean_sitter, :mean_identifier, :mean_cheater] => ((x, y, z) -> (mean(x), mean(y), mean(z))) => :means)
end
    
sim_arrow_df = tern2cart.(accuracy_of_abm3(30, 10, "other"))
sim_arrow_df.endpoints = [sim_arrow_df.type_count[i] .+ (sim_arrow_df.means[i] .- sim_arrow_df.type_count[i]) ./ 100 for i in 1:size(sim_arrow_df, 1)]
    
function ternary_arrows_sim(df)
    labels = (A = "Sitters", B =  "Identifiers", C =  "Cheaters")
    p = ternary_plot(size=(400, 400), labels=labels)
    for i in 1:size(df, 1)
        vect = df[i, :]
        xs = [vect.type_count[1], vect.endpoints[1]]
        ys = [vect.type_count[2], vect.endpoints[2]]
        plot!(p, xs, ys,
        arrow=true,
        line_z=sqrt((diff(xs).^2 + diff(ys).^2)[1]),
        lw=4,
        colour=cgrad(:viridis))
    end
    return p
end

plot_arrows_sim = ternary_arrows_sim(sim_arrow_df)

plot!(plot_arrows_sim, [x], [y], seriestype=:scatter, shape=:circle, color=:black, msize=7, msw=1, ma=1, msc=:black, msa=1)

plot_arrows_sim
plot_arrows_anal


# Plotting a single run of the model
begin
    model = evolutionary_model(;
        num_sitters=20,
        num_identifiers=20,
        num_cheaters=20,
        hatch_utility=4,
        egg_cost=0.9,
        identify_cost=0.9,
        eggs_laid=2,
        p_identify=1,
        p_mutation=0.2
    )

    type_count(model) = model.nagents_type
    mdata = [type_count]

    _, results = run!(model, agent_step!, model_step!, 1000; mdata)

    results_vecs = [[results.type_count[i][j] for i in 1:size(results, 1)] for j in 1:3]

    p_line = Plots.plot(results.step, results_vecs[1], label="Sitters", lw=2, legend=:bottomright, size=(550, 370))
    plot!(p_line, results.step, results_vecs[2], label="Identifiers", lw=2)
    plot!(p_line, results.step, results_vecs[3], label="Cheaters", lw=2)
    xlabel!(p_line, "Model Step")
    ylabel!(p_line, "Number of Agents")
end

savefig(p_line, "line_run.pdf")