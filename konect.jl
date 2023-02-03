using Downloads
using Tar
using CodecBzip2
using Dates
using Graphs
using Glob

# START: INCLUDE YOUR KONECT CONFIGURATION
include("douban_konect.jl")
# END

const TMP_FOLDER = joinpath(pwd(), "tmp")
const GRAPHS_FOLDER = joinpath(pwd(), "graphs")

const GRAPH_FILENAME_LG = "$GRAPH_NAME.lg"
const GRAPH_FILENAME_MAXCC_LG = "$GRAPH_NAME.maxcc.lg"

function create_temp_dir()
    isdir(TMP_FOLDER) || mkdir(TMP_FOLDER)
end

function download_dataset()
    Downloads.download(DATASET_URL, joinpath(TMP_FOLDER, "dataset.tar.bz2"))
end

function decompress_dataset()
    compressed = read(joinpath(TMP_FOLDER, "dataset.tar.bz2"))
    decompressed = transcode(Bzip2Decompressor, compressed)
    tempFile::String =  "temp" * string(Dates.millisecond(now())*100) * ".tar";
    write(joinpath(TMP_FOLDER, tempFile), decompressed)
    Tar.extract(joinpath(TMP_FOLDER, tempFile), joinpath(TMP_FOLDER, "extract"))
end

function getLGFromTSV()
    isdir(GRAPHS_FOLDER) || mkdir(GRAPHS_FOLDER)
    infile::String = readdir(glob"tmp/extract/*/out.*", pwd())[1]
    outfile::String = joinpath(GRAPHS_FOLDER, GRAPH_FILENAME_LG)
    out = open(outfile, "w+")

    edges_counter::Int64 = 0
    content::String = ""
    max_node::Int64 = 0
    lines::Array = []

    for line in readlines(infile)
        if startswith(line, "%")
            continue
        end
        edges_counter += 1
        newline::String = replace(line, r"(\d+)(\s+)(\d+).*" => s"\1,\3\n")
        node1::Int64 = parse(Int64, split(line, r"\s+")[1])
        node2::Int64 = parse(Int64, split(line, r"\s+")[2])
        if (node1 > max_node)
            max_node = node1
        end
        if (node2 > max_node)
            max_node = node2
        end
        push!(lines, newline)
    end

    write(out, string(max_node) * "," * string(edges_counter) * ",u,graph\n")
    for line in lines
        write(out, line)
    end
    close(out)
end

function getMaximumConnectedComponent()
    g::SimpleGraph{Int64} = loadgraph(joinpath(GRAPHS_FOLDER, GRAPH_FILENAME_LG), "graph")
    cc = connected_components(g)
    index::Int64 = argmax(length.(cc))
    sg = induced_subgraph(g, cc[index])
    savegraph(joinpath(GRAPHS_FOLDER, GRAPH_FILENAME_MAXCC_LG), sg[1], compress=false)
end

function remove_temp_dir()
    if isdir(TMP_FOLDER)
        rm(TMP_FOLDER, recursive=true)
    end
end

function konect()
    @time remove_temp_dir()
    @time create_temp_dir()
    @time download_dataset()
    @time decompress_dataset()
    @time getLGFromTSV()
    @time getMaximumConnectedComponent()
    @time remove_temp_dir()
end

@time konect()