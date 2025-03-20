module FastSRB
    export round_equation_string, get_nary_compl, get_binary_compl, count_consts, expr_to_prefix,
               extract_operands_operators, string_expl, sample_dataset,
               sample_and_eval_one_point, sample_dataset_incremental, sample_points, round_sympy_consts

using YAML
using OrderedCollections
using Distributions
using Random
using Statistics
using SymPy

include("sample_datasets.jl")

const MAIN_BENCH = Ref{OrderedDict{String,Any}}()

function __init__()
    path = joinpath(@__DIR__, "equations.yaml")
    MAIN_BENCH[] = YAML.load_file(path; dicttype=OrderedDict{String,Any})
end

end # module FastSRB
