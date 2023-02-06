using Graphs
import Graphs.Parallel

const graphPath::String = joinpath("graphs", "douban.maxcc.lg")

"""
a.deruvo@graphmining:~/homework_graph_mining$ julia -p 32 -t 8 parallel.jl
2215.818410 seconds (8.64 M allocations: 698.367 MiB, 0.13% gc time, 0.07% compilation time)


26919 seconds (monothread and sequential) vs 2215 seconds (mutlithread and parallel): 12x faster
"""
function parallel_betweenness_centrality(graphPath)::Array{Float64}
    g::SimpleGraph{Int64} = loadgraph(graphPath, "graph")
    return Parallel.betweenness_centrality(g)
end