using Downloads
using Tar
using CSV
using DataFrames
using CodecBzip2
using Dates
using Graphs

# START: INCLUDE YOUR KONECT CONFIGURATION
include("douban_konect.jl")
# END

const DOWNLOADS_FOLDER = joinpath(pwd(), "downloads")
const DATASETS_FOLDER = joinpath(pwd(), GRAPH_NAME)
const GRAPHS_FOLDER = joinpath(pwd(), "graphs")

const DATASET_FILENAME_BZ2 = "$GRAPH_NAME.tar.bz2"
const GRAPH_PATH = joinpath(DATASETS_FOLDER, GRAPH_NAME)
const GRAPH_FILENAME_TSV = "out.$GRAPH_NAME"

const GRAPH_FILENAME_LG = "$GRAPH_NAME.lg"
const GRAPH_FILENAME_MAXCC_LG = "$GRAPH_NAME.maxcc.lg"

function download_dataset(inputDatasetUrl::String, outputDir::String, outputFileName::String)
    isdir(outputDir) || mkdir(outputDir)
    Downloads.download(inputDatasetUrl, joinpath(outputDir, outputFileName))
end

function decompress_dataset(inputDatasetPath::String, outputDir::String)
    compressed = read(inputDatasetPath)
    decompressed = transcode(Bzip2Decompressor, compressed)
    isdir(outputDir) || mkdir(outputDir)
    tempFile::String =  "temp" * string(Dates.millisecond(now())*100) * ".tar";
    write(joinpath(pwd(), tempFile), decompressed)
    Tar.extract(tempFile, outputDir)
    rm(joinpath(pwd(), tempFile), force=true)
end

function getLGFromTSV(inputGraphTSVPath::String, outputDir::String, outputFileName::String)
    infile::String = inputGraphTSVPath
    outfile::String = joinpath(outputDir, outputFileName)
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

function getMaximumConnectedComponent(inputGraphPath::String, outputDir::String, outputFileName::String)
    g::SimpleGraph{Int64} = loadgraph(inputGraphPath, "graph")
    cc = connected_components(g)
    index::Int64 = argmax(length.(cc))
    println(length(cc))
    sg = induced_subgraph(g, cc[index])
    savegraph(joinpath(outputDir, outputFileName), sg[1], compress=false)
end

function clear_context()
    rm(DOWNLOADS_FOLDER, recursive=true)
    rm(DATASETS_FOLDER, recursive=true)
end

function konect()
   @time download_dataset(DATASET_URL, DOWNLOADS_FOLDER, DATASET_FILENAME_BZ2)
   @time decompress_dataset(joinpath(DOWNLOADS_FOLDER, DATASET_FILENAME_BZ2), DATASETS_FOLDER);
   @time getLGFromTSV(joinpath(GRAPH_PATH, GRAPH_FILENAME_TSV), GRAPHS_FOLDER, GRAPH_FILENAME_LG)
   @time getMaximumConnectedComponent(joinpath(GRAPHS_FOLDER, GRAPH_FILENAME_LG), GRAPHS_FOLDER, GRAPH_FILENAME_MAXCC_LG)
   @time clear_context()
end

@time konect()

