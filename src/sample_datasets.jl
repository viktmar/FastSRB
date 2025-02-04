

function sample_dataset(name; n_points=100, method="random")

    path = joinpath(dirname(pathof(SRSD)), "..", "data", "srsd_equations.yaml")

    main_bench = YAML.load_file(path; dicttype=OrderedDict{String,Any})

    # extract by id or by name
    if name in main_bench.keys
        id = name
        val = main_bench[id]
    else
        id, val = extract_by_name(name, main_bench)
    end

    eq_string = val["prp"]
    vars_info = val["vars"]

    global data = zeros(n_points, length(vars_info)) # global required for eval to know about data

    # sample variables
    for i in 1:length(vars_info)-1
        distr, pos_neg = vars_info["v$i"]["sample_type"]
        low, upp       = vars_info["v$i"]["sample_range"]

        integer = false
        if distr == "int"
            distr = "uni"
            integer = true
        end

        data[:, i] .= sample_points( low, upp, n_points,
            method  = method,
            distr   = distr,
            pos_neg = pos_neg,
            integer = integer
        )
    end

    # make sure only allowed operators and operands & no malicious code
    allowed_operators = [:neg, :sin, :cos, :tanh, :sqrt, :neg, :exp, :log, :log10, :+, :-, :*, :/, :^]
    allowed_operands  = [Symbol("v$i") for i in 1:100]

    for r in extract_operands_operators(Meta.parse(eq_string))
        @assert r in allowed_operands || r in allowed_operators || r isa Number "$r not valid operator or operand"
    end

    # replace the vi with data[:, i]
    str = eq_string
    for i in 1:length(vars_info)-1
        str = replace(str, "v$i" => "data[:, $i]")
    end
    str = "@. " * str

    pred = eval(Meta.parse(str))
    data[:, end] .= pred

    if isfinite(sum(data))
        return data, eq_string
    else
        return sample_dataset(name; n_points=n_points, method=method)
    end
end

neg(x) = -x


