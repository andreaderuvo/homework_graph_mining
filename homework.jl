"""
Graph Mining Homework

Student: Andrea de Ruvo
Professor: Pierluigi Crescenzi

Most of the code is a copy paste of Pierluigi Crescenzi's codes (https://github.com/piluc/GraphMining/tree/main/code).
Plots package is commented due to problems to have a running version on Windows.

Code link:
LG Graph link:
"""

using Graphs
using Printf
using LinearAlgebra
using StatsBase
using SortingAlgorithms
using Plots

""" Exercise 1 """
function exercise1(graphPath::String)
    @printf("\n\n")
    @printf("-----------------------\n")
    @printf("Exercise 1\n")
    @printf("-----------------------\n")
    g::SimpleGraph{Int64} = loadgraph(graphPath, "graph")
    @time @printf("Nodes: %d\n", Graphs.nv(g))
    @time @printf("Edges: %d\n", Graphs.ne(g))
    @time @printf("Density: %f\n", Graphs.density(g))
    @time @printf("Min Degree: %d\n", Graphs.δ(g))
    @time @printf("Max Degree: %d\n", Graphs.Δ(g))
    @time @printf("Average Degree: %f\n", 2 * Graphs.ne(g) / Graphs.nv(g))
    nothing
end

""" Exercise 2 """
function exercise2(graphPath::String)
    @printf("\n\n")
    @printf("--------------------------------------\n")
    @printf("Exercise 2: Degrees of Separation\n")
    @printf("--------------------------------------\n")
    g::SimpleGraph{Int64} = loadgraph(graphPath, "graph")
    s::Int64 = 0
    for x::Int64 in vertices(g)
        d::Array{Int64} = gdistances(g, x)
        s = s + sum(d)
    end
    nvg::Int64 = nv(g)
    @printf("Value: %f\n", s / (nvg * (nvg - 1)))
    nothing
end

function exercise2_mt(graphPath::String)
    @printf("\n\n")
    @printf("-----------------------------------------------------\n")
    @printf("Exercise 2 (MultiThreading): Degrees of Separation\n")
    @printf("-----------------------------------------------------\n")
    g::SimpleGraph{Int64} = loadgraph(graphPath, "graph")
    s::Int64 = 0
    l = Threads.SpinLock()
    Threads.@threads for x::Int64 in vertices(g)
        d::Array{Int64} = gdistances(g, x)
        Threads.lock(l)
        s = s + sum(d)
        Threads.unlock(l)
    end
    nvg::Int64 = nv(g)
    @printf("Value: %f\n", s / (nvg * (nvg - 1)))
    nothing
end


""" Exercise 3 """
function degrees_of_separation(dd::Array{Float64})::Float64
    last_distance::Int64 = findlast(x -> x > 0, dd)
    return dot(1:last_distance, dd[1:last_distance])
end

function distance_distribution(g::SimpleGraph{Int64}, k::Int64)::Array{Float64}
    nvg::Int64 = nv(g)
    dd::Array{Int64} = zeros(Int64, nvg - 1)
    for _ in 1:k
        dd = dd + counts(gdistances(g, rand(1:nvg)), 1:nvg-1)
    end
    return dd / (k * (nvg - 1))
end

function distance_distribution_mt(g::SimpleGraph{Int64}, k::Int64)::Array{Float64}
    nvg::Int64 = nv(g)
    dd::Array{Int64} = zeros(Int64, nvg - 1)
    l = Threads.SpinLock()
    Threads.@threads for _ in 1:k
        Threads.lock(l)
        dd = dd + counts(gdistances(g, rand(1:nvg)), 1:nvg-1)
        Threads.unlock(l)
    end
    return dd / (k * (nvg - 1))
end

function distance_distribution(g::SimpleGraph{Int64})::Array{Float64}
    nvg::Int64 = nv(g)
    dd::Array{Int64} = zeros(Int64, nvg - 1)
    for x::Int64 in vertices(g)
        dd = dd + counts(gdistances(g, x), 1:nvg-1)
    end
    return dd / (nvg * (nvg - 1))
end

function distance_distribution_mt(g::SimpleGraph{Int64})::Array{Float64}
    nvg::Int64 = nv(g)
    dd::Array{Int64} = zeros(Int64, nvg - 1)
    l = Threads.SpinLock()
    Threads.@threads for x::Int64 in vertices(g)
        Threads.lock(l)
        dd = dd + counts(gdistances(g, x), 1:nvg-1)
        Threads.unlock(l)
    end
    return dd / (nvg * (nvg - 1))
end

function exercise3(graphPath::String, multiplier::Int64)
    @printf("\n\n")
    @printf("------------------------------------------------------\n")
    @printf("Exercise 3: Approximation of Degrees of Separation\n")
    @printf("------------------------------------------------------\n")
    g::SimpleGraph{Int64} = loadgraph(graphPath, "graph")
    k::Int64 = multiplier * trunc(log2(nv(g)))
    @printf("Sample size: %d\n", k)
    dd_apx::Array{Float64} = distance_distribution(g, k)
    @printf("Value: %f\n", degrees_of_separation(dd_apx))
    nothing
end

function exercise3_mt(graphPath::String, multiplier::Int64)
    @printf("\n\n")
    @printf("------------------------------------------------------\n")
    @printf("Exercise 3: Approximation of Degrees of Separation\n")
    @printf("------------------------------------------------------\n")
    g::SimpleGraph{Int64} = loadgraph(graphPath, "graph")
    k::Int64 = multiplier * trunc(log2(nv(g)))
    @printf("Sample size: %d\n", k)
    dd_apx::Array{Float64} = distance_distribution_mt(g, k)
    @printf("Value: %f\n", degrees_of_separation(dd_apx))
    nothing
end

""" Exercise Plot"""
function exercise_plot(graphPath::String)
    @printf("\n\n")
    @printf("-----------------------------------------------------------------------------------------------------------------------------------------------------------------------\n")
    @printf("Exercise 3 plot: Include a figure with the plots of the exact and approximate distance distribution (similar to the right part of Figure 2.3 in the lecture notes).\n")
    @printf("-----------------------------------------------------------------------------------------------------------------------------------------------------------------------\n")
    g::SimpleGraph{Int64} = loadgraph(graphPath, "graph")
    k::Int64 = 100 * trunc(log2(nv(g)))
    @time dd_apx::Array{Float64} = distance_distribution_mt(g, k)
    @time dd_exact::Array{Float64} = distance_distribution_mt(g)
    plot(xlabel = "Distance h", ylabel= "Exact and approximate value dd(h)")
    plot!(dd_exact[1:20], label="exact value", markershape=:circle)
    plot!(dd_apx[1:20], label="approximate value", markershape=:square)
    #nothing
end

""" Exercise 4 """
function exercise4(graphPath::String)
    @printf("\n\n")
    @printf("------------------------------------------------------\n")
    @printf("Exercise 4: Diameter textbook algorithm\n")
    @printf("------------------------------------------------------\n")
    g::SimpleGraph{Int64} = loadgraph(graphPath, "graph")
    lb::Int64 = maximum(gdistances(g, rand(1:nv(g))))
    @printf("Value: %d <= D <= %d\n", lb, 2 * lb)
    nothing
end

""" Exercise 5 """
function exercise5(graphPath::String, k::Int64)
    @printf("\n\n")
    @printf("------------------------------------------------------\n")
    @printf("Exercise 5: 2-sweep algorithm (100 runs)\n")
    @printf("------------------------------------------------------\n")
    g::SimpleGraph{Int64} = loadgraph(graphPath, "graph")
    value::Int64 = 0
    for _ in 1:k
        lb::Int64, y::Int64 = findmax(gdistances(g, rand(1:nv(g))))
        temp::Int64 = max(lb, maximum(gdistances(g, y)))
        if (temp > value)
            value = temp
        end
    end
    @printf("Value: %d\n", value)
    nothing
end

""" Exercise 6 """
function max_degree_node(g::SimpleGraph{Int64})::Int64
    _, u = findmax(degree_centrality(g, normalize=false))
    return u
end

function exercise6(graphPath::String)
    @printf("\n\n")
    @printf("------------------------------------------------------\n")
    @printf("Exercise 6: iFUB algorithm\n")
    @printf("------------------------------------------------------\n")
    g::SimpleGraph{Int64} = loadgraph(graphPath, "graph")
    d::Array{Int64}, nbfs::Int64 = gdistances(g, max_degree_node(g)), 1
    node_index::Array{Int64} = sortperm(d, alg=RadixSort, rev=true)
    c::Int64, i::Int64, L::Int64, U::Int64 = 1, d[node_index[1]], 0, nv(g)
    while (L < U)
        U, L = nv(g), max(L, maximum(gdistances(g, node_index[c])))
        nbfs, c = nbfs + 1, c + 1
        if (d[node_index[c]] == i - 1)
            U, i = 2 * (i - 1), i - 1
        end
    end
    @printf("Value: %d\n", L)
    @printf("Number of BFSs: %d\n", nbfs)
    nothing
end

""" Exercise 7 """
function exercise7(graphPath::String)
    @printf("\n\n")
    @printf("------------------------------------------------------\n")
    @printf("Exercise 7: Degree centrality\n")
    @printf("------------------------------------------------------\n")

    g::SimpleGraph{Int64} = loadgraph(graphPath, "graph")
    degree_centrality(g, normalize=false)
    nothing
end

""" Exercise 8 """
function exercise8(graphPath::String)
    @printf("\n\n")
    @printf("------------------------------------------------------\n")
    @printf("Exercise 8: Eccentricity centrality\n")
    @printf("------------------------------------------------------\n")

    g::SimpleGraph{Int64} = loadgraph(graphPath, "graph")
    1 ./ eccentricity(g)
    nothing
end

""" Exercise 9 """
function exercise9(graphPath::String)
    @printf("\n\n")
    @printf("------------------------------------------------------\n")
    @printf("Exercise 9: Closeness centrality\n")
    @printf("------------------------------------------------------\n")

    g::SimpleGraph{Int64} = loadgraph(graphPath, "graph")
    closeness_centrality(g)
    nothing
end

""" Exercise 10 """
function exercise10(graphPath::String)
    @printf("\n\n")
    @printf("------------------------------------------------------\n")
    @printf("Exercise 10: Betweenness centrality\n")
    @printf("------------------------------------------------------\n")

    g::SimpleGraph{Int64} = loadgraph(graphPath, "graph")
    betweenness_centrality(g)
    nothing
end

""" Exercise 11 """
function exercise11(graphPath::String)
    @printf("\n\n")
    @printf("-------------------------------------------------------------------------------------------------------------------------------------\n")
    @printf("Exercise 11: Insert the values in the following table of correlation between the four centrality measures we have seen in class.\n")
    @printf("-------------------------------------------------------------------------------------------------------------------------------------\n")

    g::SimpleGraph{Int64} = loadgraph(graphPath, "graph")

    @time d::Array{Float64} = degree_centrality(g)
    @time e::Array{Float64} = 1 ./ eccentricity(g)
    @time c::Array{Float64} = closeness_centrality(g)
    @time b::Array{Float64} = betweenness_centrality(g)
    
    println([[cor(d, e), cor(d, c), cor(d, b)], [cor(e, c), cor(e, b)], [cor(c, b)]])

    @printf("Correlation(degree,eccentricity): %f\n", cor(d, e))
    @printf("Correlation(degree,closeness): %f\n", cor(d, c))
    @printf("Correlation(degree,betweenness): %f\n", cor(d, b))
    @printf("Correlation(eccentricity,closeness): %f\n", cor(e, c))
    @printf("Correlation(eccentricity,betweenness): %f\n", cor(e, b))
    @printf("Correlation(closeness,betweenness): %f\n", cor(c, b))

    nothing
end

""" Exercise 12 """
function exercise12(graphPath::String, k::Int64)
    @printf("\n\n")
    @printf("------------------------------------------------------\n")
    @printf("Exercise 12: Approximation of closeness centrality\n")
    @printf("------------------------------------------------------\n")

    @time begin
        g::SimpleGraph{Int64} = loadgraph(graphPath, "graph")
        farness::Array{Float64} = zeros(Float64, nv(g))
        for _ in 1:k
            farness = farness + gdistances(g, rand(1:nv(g)))
        end
        @printf("Sample size: %d\n", k)

        apx_centrality::Array{Float64} = (k * (nv(g) - 1)) ./ (nv(g) .* farness)
    end
    exact_centrality::Array{Float64} = closeness_centrality(g)
    @printf("Correlation with the exact values: %f\n", cor(apx_centrality, exact_centrality))
    nothing
end

""" Exercise 13 """
function exercise13(graphPath::String)
    @printf("\n\n")
    @printf("------------------------------------------------------\n")
    @printf("Exercise 13: Top node with respect to closeness\n")
    @printf("------------------------------------------------------\n")
    g::SimpleGraph{Int64} = loadgraph(graphPath, "graph")
    c = closeness_centrality(g)
    t = argmax(c)
    @printf("Node: %d\n", t)
    nothing
end


const graphPath::String = joinpath("graphs", "douban.maxcc.lg")

#@time exercise1(graphPath)
#@time exercise2(graphPath)
#@time exercise2_mt(graphPath)
#@time exercise3(graphPath, 100)
#@time exercise_plot(graphPath)
#@time exercise4(graphPath)
#@time exercise5(graphPath, 100)
#@time exercise6(graphPath)
#@time exercise7(graphPath)
#time exercise8(graphPath)
#@time exercise9(graphPath)
#@time exercise10(graphPath)
#@time exercise11(graphPath)
@time exercise12(graphPath, 10000)
#@time exercise13(graphPath)