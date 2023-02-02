using Graphs
import Graphs.Parallel

const graphPath::String = joinpath("graphs", "douban.maxcc.lg")

function parallel_betweenness_centrality(graphPath)::Array{Float64}
    g::SimpleGraph{Int64} = loadgraph(graphPath, "graph")
    return Parallel.betweenness_centrality(g)
end