module SRSD

using YAML
using OrderedCollections
using Distributions
using Random

include("sample_datasets.jl")

const MAIN_BENCH = Ref{OrderedDict{String,Any}}()

function __init__()
    path = joinpath(@__DIR__, "srsd_equations.yaml")
    MAIN_BENCH[] = YAML.load_file(path; dicttype=OrderedDict{String,Any})
end

end # module SRSD
