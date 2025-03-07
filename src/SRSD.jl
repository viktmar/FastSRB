module SRSD
    export round_equation_string, get_nary_compl, get_binary_compl, expr_to_prefix,
               extract_operands_operators, string_expl, sample_dataset,
               sample_and_eval_one_point, sample_dataset_incremental, sample_points

using YAML
using OrderedCollections
using Distributions
using Random
using Statistics

include("sample_datasets.jl")

const MAIN_BENCH = Ref{OrderedDict{String,Any}}()

function __init__()
    path = joinpath(@__DIR__, "srsd_equations.yaml")
    MAIN_BENCH[] = YAML.load_file(path; dicttype=OrderedDict{String,Any})
end

end # module SRSD
