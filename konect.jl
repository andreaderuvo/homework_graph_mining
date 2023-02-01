using Downloads
using Tar
using CSV
using DataFrames
using CodecBzip2
using Dates

# START: INCLUDE YOUR KONECT CONFIGURATION
include("douban_konect.ji")
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
    tempFile::string =  "temp" * string(Dates.millisecond(now())*100) * ".tar";
    write(joinpath(pwd(), tempFile), decompressed)
    Tar.extract(tempFile, outputDir)
    rm(joinpath(pwd(), tempFile), force=true)
end

function getLGFromTSV(inputGraphTSVPath::String, outputDir::String, outputFileName::String)
    df = CSV.read(inputGraphTSVPath, DataFrame, header=1, delim=' ')
    edges::String = names(df)[2]
    nodes::String = names(df)[3]
    DataFrames.rename!(df, [Symbol("Col$i") for i in 1:size(df, 2)])
    isdir(outputDir) || mkdir(outputDir)
    CSV.write(joinpath(outputDir, outputFileName), select(df, "Col1" => nodes, "Col2" => edges, "Col3" => "u"); delim=',')
end

function getMaximumConnectedComponent(inputGraphPath::String, outputDir::String, outputFileName::String)
    g::SimpleGraph{Int64} = loadgraph(inputGraphPath, "graph")
    cc = connected_components(g)
    index::Int64 = argmax(length.(cc))
    sg = induced_subgraph(g, cc[index])
    savegraph(joinpath(outputDir, outputFileName), sg[1], compress=false)
end

function clear_context() {
    rm(DOWNLOADS_FOLDER, recursive=true)
    rm(DATASETS_FOLDER, recursive=true)
}

function konect() {
    @time download_dataset(DATASET_URL, DOWNLOADS_FOLDER, DATASET_FILENAME_BZ2)
    @time decompress_dataset(joinpath(DOWNLOADS_FOLDER, DATASET_FILENAME_BZ2), DATASETS_FOLDER);
    @time getLGFromTSV(joinpath(GRAPH_PATH, GRAPH_FILENAME_TSV), GRAPHS_FOLDER, GRAPH_FILENAME_LG)
    @time getMaximumConnectedComponent(joinpath(GRAPHS_FOLDER, GRAPH_FILENAME_LG), GRAPHS_FOLDER, GRAPH_FILENAME_MAXCC_LG)
}

@time konect()

