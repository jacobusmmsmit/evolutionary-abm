using Agents
using Distributions
using StatsBase
using DataFrames
using Plots
using Test


include("src\\evolutionary_model.jl");
include("src\\helper_functions.jl");
include("src\\plot_backend.jl");


#### View the evolution of a single model over a number of steps #####
model = evolutionary_model(;
    num_sitters=20,
    num_identifiers=20,
    num_cheaters=20,
    hatch_utility=4,
    egg_cost=0.9,
    identify_cost=0.9,
    eggs_laid=1,
    p_identify=1,
    p_mutation=0.2
)

# Functions to collect data
sitters(a) = typeof(a) == Sitter
identifiers(a) = typeof(a) == Identifier
cheaters(a) = typeof(a) == Cheater
adata = [(sitters, count), (identifiers, count), (cheaters, count)]

results, _ = run!(model, agent_step!, model_step!, 1000; adata=adata);

p_line = Plots.plot(results.step, results.count_sitters, label="Sitters", lw=2, legend=:topleft)
plot!(p_line, results.count_identifiers, label="Identifiers",lw=2)
plot!(p_line, results.count_cheaters, label="Cheaters", lw=2)
xlabel!(p_line, "Model Step")
ylabel!(p_line, "Number of Agents")

#### Ternary plot of previous model #####
nsitters = results[:, :count_sitters] ./ 60
nidentifiers = results[:, :count_identifiers] ./ 60
ncheaters = 1 .- (nsitters .+ nidentifiers)

points = tern2cart.(nsitters, nidentifiers, ncheaters)

anim2 = @animate for i = 3:length(x)
    p_anim2 = ternary_plot(
        labels = (A = "Sitters (%)", B = "Identifiers (%)", C = "Cheaters (%)"),
    )

    points_to_plot = points[1:i-1]
    x_to_plot = first.(points_to_plot)
    y_to_plot = last.(points_to_plot)

    Plots.plot!(
        p_anim2,
        x_to_plot,
        y_to_plot,
        alpha = 0.1,
        seriestype = :scatter,
    )
    current_points = points[(i-1):i]
    if !all(current_points[1] .≈ current_points[2])
        Plots.plot!(
            p_anim2,
            first.(current_points),
            last.(current_points),
            linealpha=0.7,
            lw=5,
            linecolour=:red,
            arrow=true)
    else
        Plots.plot!(
            p_anim2,
            [first(current_points[1])],
            [last(current_points[1])],
            seriestype = :scatter,
            colour = :red)
    end
end



# Uncomment to save the gif
gif(anim2, "plots/evo-abm-equilateral-animated.gif", fps = 60)

### Ternary quiver plots for replicator dynamics #####

final_results = DataFrame(
    xstart=Float64[],
    xend=Float64[],
    ystart=Float64[],
    yend=Float64[],
)

model = evolutionary_model(;
            num_sitters=0,
            num_identifiers=0,
            num_cheaters=0,
            hatch_utility=4,
            egg_cost=1.1,
            identify_cost=0.8,
            eggs_laid=1,
            p_identify=1,
            p_mutation=0.2
        )

total_agents = 50
for i in 1:(total_agents-1), j in 1:total_agents - i -1
    initialise_agents!(model, i, j, total_agents - i - j)

    results, _ = run!(model, agent_step!, model_step!, 1; adata=adata, replicates=100);
    
    results = results |>
        df -> filter(:step => !=(0), df) |>
        df -> combine(df, :count_sitters => mean => :xend, :count_identifiers => mean => :yend)
    results[:, :xstart] .= i
    results[:, :ystart] .= j
    final_results = [final_results; results]
end

## This code runs on DataFrames v0.21

r = final_results ./ total_agents |>
    x -> transform(x, [:xstart, :ystart,:xend,  :yend] => ByRow(magangle) => :magangle) |>
    x -> transform(x, :magangle => ByRow(x -> x[1]) => :mag) |>
    x -> select(x, Not(:magangle)) |>
    x -> transform(x, [:xstart, :xend, :ystart, :yend, :mag] => ByRow(
            (x1, x2, y1, y2, mag) -> ifelse(mag > 0, ([x2, y2] - [x1, y1]) ./ (mag * 30) + [x1, y1], [x2, y2])
         ) => :newpoints) |>
    x -> transform(x, :newpoints => ByRow(x -> x[1]) => :newxend) |>
    x -> transform(x, :newpoints => ByRow(x -> x[2]) => :newyend) |>
    x -> filter(row -> row[:mag] > 0, x) |>
    x -> transform(x, :mag => (x -> rescale(log.(x))) => :rescalemag) |>
    x -> select(x, Not(:newpoints));

## Code below requires DataFrames v0.22 >

# r = final_results./total_agents |>
#     x -> transform(x, [:xstart, :ystart,:xend,  :yend] => ByRow(magangle) => [:mag, :angle]) |>
#     x -> transform(x, [:xstart, :xend, :ystart, :yend, :mag] => ByRow(
#             (x1, x2, y1, y2, mag) -> ifelse(mag > 0, ([x2, y2] - [x1, y1]) ./ (mag*30) + [x1, y1], [x2, y2])
#         ) => [:newxend, :newyend]) |>
#     x -> transform(x, :mag => (x -> rescale(log.(x))) => :rescalemag) |>
#     x -> select(x, Not(:angle));

## Quiver Plots
start_points = tern2cart.(r.xstart, 1 .- r.xstart .- r.ystart, r.ystart)
end_points = tern2cart.(r.xend, 1 .- r.xend .- r.yend, r.yend)
scaled_end_points = tern2cart.(r.newxend, 1 .- r.newxend .- r.newyend, r.newyend)

p_quiver1 = ternary_plot(
    labels = (A = "Sitters (%)", B = "Identifiers (%)", C = "Cheaters (%)"),
)

for i in 1:size(r)[1]
    Plots.plot!(
        p_quiver1,
        first.([start_points[i], end_points[i]]),
        last.([start_points[i], end_points[i]]),
        arrow=true,
        line_z=log(r[i, :mag]),
        lw=0.55,
        colour=cgrad(:redsblues, rev=true))
end

p_quiver2 = ternary_plot(
    labels = (A = "Sitters (%)", B = "Identifiers (%)", C = "Cheaters (%)"),
)



for i in 1:size(r)[1]
    Plots.plot!(
        p_quiver2,
        first.([start_points[i], scaled_end_points[i]]),
        last.([start_points[i], scaled_end_points[i]]),
        arrow=true,
        line_z=log(r[i, :mag]),
        lw=0.55,
        colour=cgrad(:redsblues, rev=true))
end

p_quiver1
p_quiver2