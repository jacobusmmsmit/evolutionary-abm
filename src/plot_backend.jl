using Plots
using LinearAlgebra
using StaticArrays

# dist_from_graph = 0.04
# arrow_length = 0.4

function tern2cart(a, b, c)
    (1/2 * (2b+c)/(a+b+c), √3/2 * (c/(a+b+c)))
end

function tern2cart(array)
    a = array[1]
    b = array[2]
    c = array[3]
    (1/2 * (2b+c)/(a+b+c), √3/2 * (c/(a+b+c)))
end

function cart2tern(x, y)
    c = (2*y)/√3
    b = x - c/2
    a = 1 - b - c
    return (a , b , c)
end

function cart2tern(array)
    x = array[1]
    y = array[2]
    c = (2*y)/√3
    b = x - c/2
    a = 1 - b - c
    return (a , b , c)
end

function ternary_plot(;
        title = "",
        size = nothing,
        dist_from_graph::Real = 0.04,
        arrow_length::Real = 0.4,
        tick_length::Real = 0.015,
        labels = (A = "A (%)", B = "B (%)", C = "C (%)"))
    if size == nothing
        if title == "" 
            size = (570, 550)
        else
            size = (570, 570)
        end
    end
        
    arrow_pos = (1-arrow_length)/2, 1 - (1-arrow_length)/2

    p = Plots.plot(
        xlims=(-0.1, 1.1),
        ylims=(-√3/2 * 4 * dist_from_graph, √3/2 * (1 + 2*dist_from_graph)),
        xaxis=false,
        yaxis=false,
        grid=false,
        ticks=false,
        legend=false,
        title = title,
        size = size,)

    Plots.plot!(p, [0, 1], [0, 0], colour=:black)
    Plots.plot!(p, [0, 1/2], [0, √3/2], colour=:black)
    Plots.plot!(p, [1, 1/2], [0, √3/2], colour=:black)

    



    # A-Axis Grid
    for i in 0.0:0.2:1
        start_point = tern2cart(1-i, i, 0)
        end_point = tern2cart(1-i, 0, i)
        tick_offset = normalize(collect(start_point .- end_point))./(1/tick_length)
        tick_end_point = start_point .- tick_offset
        tick_textpos = start_point .+ [0.5 * dist_from_graph*0.8, -dist_from_graph*0.8]
        Plots.annotate!(p, tick_textpos[1], tick_textpos[2], Plots.text("$(round(1-i, sigdigits=2))", 7, rotation=0))
        Plots.plot!(p, [start_point[1], end_point[1]], [start_point[2], end_point[2]], colour=:black, alpha=0.5, linewidth=0.5)
        Plots.plot!(p, [start_point[1], tick_end_point[1]], [start_point[2], tick_end_point[2]], colour=:black)
    end

    # B-Axis Grid
    for i in 0:0.2:1
        end_point = tern2cart(1-i, i, 0)
        start_point = tern2cart(0, i, 1-i)
        tick_offset = normalize(collect(start_point .- end_point))./(1/tick_length)
        tick_end_point = start_point .- tick_offset
        tick_textpos = start_point .+ [0.5 * dist_from_graph*0.8, dist_from_graph*0.8]
        Plots.annotate!(p, tick_textpos[1], tick_textpos[2], Plots.text("$i", 7, rotation=0))
        Plots.plot!(p, [start_point[1], end_point[1]], [start_point[2], end_point[2]], colour=:black, alpha=0.5, linewidth=0.5)
        Plots.plot!(p, [start_point[1], tick_end_point[1]], [start_point[2], tick_end_point[2]], colour=:black)
    end

    # C-Axis Grid
    for i in 0:0.2:1
        start_point = tern2cart(1-i, 0, i)
        end_point = tern2cart(0, 1-i, i)
        tick_offset = normalize(collect(start_point .- end_point))./(1/tick_length)
        tick_end_point = start_point .- tick_offset
        tick_textpos = start_point .+ [-dist_from_graph*0.8, 0]
        Plots.annotate!(p, tick_textpos[1], tick_textpos[2], Plots.text("$i", 7, rotation=0))
        Plots.plot!(p, [start_point[1], end_point[1]], [start_point[2], end_point[2]], colour=:black, alpha=0.5, linewidth=0.5)
        Plots.plot!(p, [start_point[1], tick_end_point[1]], [start_point[2], tick_end_point[2]], colour=:black)
    end

    ## Axis labels
    # C axis
    pos = collect(tern2cart(arrow_pos[2], 0, arrow_pos[1])) .+ (2 .* [-dist_from_graph, dist_from_graph])
    pos2 = collect(tern2cart(arrow_pos[1], 0, arrow_pos[2])) .+ (2 .* [-dist_from_graph, dist_from_graph])
    textpos = ((pos .+ pos2) ./ 2).+ [-dist_from_graph, dist_from_graph]
    plot!(p, [pos[1], pos2[1]], [pos[2], pos2[2]], arrow=true, colour=:black)
    annotate!(p, textpos[1], textpos[2], Plots.text(labels[:C], 10, :dark, rotation = 60))

    # B axis
    pos = collect(tern2cart(0, arrow_pos[1], arrow_pos[2])) .+ (2 .* [dist_from_graph, dist_from_graph])
    pos2 = collect(tern2cart(0, arrow_pos[2], arrow_pos[1])) .+ (2 .* [dist_from_graph, dist_from_graph])
    textpos = ((pos .+ pos2) ./ 2).+ [dist_from_graph, dist_from_graph]
    plot!(p, [pos[1], pos2[1]], [pos[2], pos2[2]], arrow=true, colour=:black)
    annotate!(p, textpos[1], textpos[2], Plots.text(labels[:B], 10, :dark, rotation = -60))

    # A axis
    pos = collect(tern2cart(arrow_pos[1], arrow_pos[2], 0)) .+ (2 .* [0, -dist_from_graph])
    pos2 = collect(tern2cart(arrow_pos[2], arrow_pos[1], 0)) .+ (2 .* [0, -dist_from_graph])
    textpos = ((pos .+ pos2) ./ 2) .+ [0, -dist_from_graph]
    plot!(p, [pos[1], pos2[1]], [pos[2], pos2[2]], arrow=true, colour=:black)
    annotate!(p, textpos[1], textpos[2], Plots.text(labels[:A], 10, :dark, rotation = 0))

    return p
end

# p = ternary_plot(
#     title="Distribution of A, B, and C in system",
#     labels = (A = "Cheaters (%)", B = "Sitters (%)", C = "Idenfitiers (%)"),
# )

## Plotting Points
# npoints = 10
# points = [Vector{Float64}() for i in 1:npoints]
# accepted_points = 0

# while accepted_points < npoints
#     point = rand(SVector{2, Float64})
#     if sum(point) <= 1
#         points[accepted_points+1] = vcat(point, 1 - sum(point))
#         accepted_points += 1
#     end
# end

# points_to_plot = tern2cart.(points)
# x_to_plot = first.(points_to_plot)
# y_to_plot = last.(points_to_plot)

# Plots.plot!(p, x_to_plot, y_to_plot, seriestype = :scatter)
