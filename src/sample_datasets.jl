
# ==================================================================================================
# helpers
# ==================================================================================================
# operator definitions # ---------------------------------------------------------------------------
neg(x) = -x

# various equation string processing #  ------------------------------------------------------------
""" round numbers in an equation string and return a string
"""
round_equation_string(str::String; sigdigits=3) = string(round_equation_string(Meta.parse(str), sigdigits=sigdigits))
round_equation_string(num::Number; sigdigits=3) = round(num, sigdigits=sigdigits)
round_equation_string(else_; sigdigits=3) = else_

function round_equation_string(expr::Expr; sigdigits=3)
    map!(s -> round_equation_string(s, sigdigits=sigdigits), expr.args, expr.args)
    expr
end

""" determine the complexity n-ary complexity.
"""
get_nary_compl(expr::String) = get_nary_compl(Meta.parse(expr))

function get_nary_compl(expr)
    !(expr isa Expr) && return 1
    return sum(get_nary_compl(a) for a in  expr.args)
end

""" determine the binary complexity.
"""
get_binary_compl(expr::String) = get_binary_compl(Meta.parse(expr))
get_binary_compl(expr)         = length(expr_to_prefix(expr))

""" convert an n-ary julia expression to an binray prefix array.
"""
expr_to_prefix(expr::Expr) = expr_to_prefix(expr.args)
expr_to_prefix(expr::T) where {T <: Rational} = [Float64(expr)]
expr_to_prefix(expr) = [expr]

function expr_to_prefix(expr::Vector)
    arr = []
    for (i, ex) in enumerate(expr)
        if i > 1 && length(expr) - i > 1  # required to convert n-ary to binary
            append!(arr, expr_to_prefix(expr[1]))
        end

        ret = expr_to_prefix(ex)
        append!(arr, ret)
    end
    return arr
end

""" extract all operators and operands from an equation to make sure there is
    nothing malicious before using eval
"""
extract_operands_operators(expr::String) = extract_operands_operators(Meta.parse(expr))
function extract_operands_operators(expr)
    result = []
    if expr isa Number || expr isa Symbol
        push!(result, expr)
    elseif expr isa Expr
        if expr.head == :call
            push!(result, expr.args[1])  # Operator
            for arg in expr.args[2:end]
                append!(result, extract_operands_operators(arg))
            end
        end
    end
    return result
end

""" convert an expression or a string to a string including all operators, like: 2v1 -> 2 * v1
"""
string_expl(e::String) = string_expl(Meta.parse(e))
string_expl(e) = string(e)
function string_expl(e::Expr)
    if length(e.args) == 3
        return "(" * string_expl(e.args[2]) * string_expl(e.args[1]) * string_expl(e.args[3]) * ")"
    elseif length(e.args) == 2
        return string_expl(e.args[1]) * "(" * string_expl(e.args[2]) * ")"
    else
        return "(" * join([string_expl(arg) for arg in e.args[2:end]], string_expl(e.args[1])) * ")"
    end
end

# ==================================================================================================
# sampling
# ==================================================================================================

function sample_dataset(
    eq_id::String;
    n_points   = 100,
    method     = "random",
    max_trials = 100,
    allowed_equation_elements = [
        :+, :-, :*, :/, :^,                         # binary operators
        :neg, :sin, :cos, :tanh, :sqrt, :exp, :log, # unary operators
        [Symbol("v$i") for i in 1:100]...],         # variables v1, ..., v100
    incremental = false,
)
    # extract correct equation
    @assert eq_id in MAIN_BENCH[].keys "could not find eq_id"

    method == "range" && incremental && @warn "Sampling along a range does not make sense incrementally. Consider setting incremental=false"

    val = MAIN_BENCH[][eq_id]

    if incremental
        return sample_dataset_incremental(
            val;
            n_points   = n_points,
            method     = method,
            max_trials = max_trials,
            allowed_equation_elements = allowed_equation_elements
        )
    else
        return sample_dataset(
            val;
            n_points   = n_points,
            method     = method,
            max_trials = max_trials,
            allowed_equation_elements = allowed_equation_elements
        )
    end
end

function sample_dataset(
    val::OrderedDict;
    n_points   = 100,
    method     = "random",
    max_trials = 100,
    allowed_equation_elements = [
        :+, :-, :*, :/, :^,                         # binary operators
        :neg, :sin, :cos, :tanh, :sqrt, :exp, :log, # unary operators
        [Symbol("v$i") for i in 1:100]...],         # variables v1, ..., v100
)

    eq_string = val["prp"]
    # make sure no malicious code
    for r in extract_operands_operators(eq_string)
        @assert r in allowed_equation_elements || r isa Number "$r not valid operator or operand"
    end

    # prepare data variable -> needs to be global for eval to wark
    vars_info = val["vars"]
    global data = zeros(n_points, length(vars_info))

    # replace the vi with data[:, i]
    str = eq_string
    for i in 1:length(vars_info)-1
        eq_string = replace(eq_string, "v$i" => "data[:, $i]")
    end
    eq_string = "@. " * eq_string
    eq_expr = Meta.parse(eq_string)

    # sample independet variables # ----------------------------------------------------------------
    for i in 1:length(vars_info)-1
        distr, pos_neg = vars_info["v$i"]["sample_type"]
        low, upp       = vars_info["v$i"]["sample_range"]

        integer = false
        if distr == "int"
            distr = "uni"
            integer = true
        end

        data[:, i] .= sample_points(low, upp, n_points,
            method  = method,
            distr   = distr,
            pos_neg = pos_neg,
            integer = integer
        )
    end

    # calculate dependent variable # ---------------------------------------------------------------
    pred = try
        pred = eval(eq_expr)
    catch
        if max_trials > 0
            println("resampling data set...")
            sample_dataset(
                val;
                n_points   = n_points,
                method     = method,
                max_trials = max_trials - 1,
                allowed_equation_elements = allowed_equation_elements
            )
        else
            throw("cannot sample data. keeps raising exceptions. try setting incremental=true")
        end
    end

    data[:, end] .= pred

    # redo if non-finite # -------------------------------------------------------------------------
    if isfinite(sum(data))
        return data
    else
        return sample_dataset(
            val;
            n_points   = n_points,
            method     = method,
            max_trials = max_trials - 1,
            allowed_equation_elements = allowed_equation_elements
        )
    end
end


function sample_and_eval_one_point(eq_expr, vars_info, vars, method; max_trials=100)
    # sample one set of independet variables
    vars[1:end-1] .= map(1:length(vars_info)-1) do i
        distr, pos_neg = vars_info["v$i"]["sample_type"]
        low, upp       = vars_info["v$i"]["sample_range"]

        integer = false
        if distr == "int"
            distr = "uni"
            integer = true
        end

        return sample_points(low, upp, 1,
            method  = method,
            distr   = distr,
            pos_neg = pos_neg,
            integer = integer
        )[1]
    end

    # try eval for dependent variable. if fails or non-finite, try again with new independet variables
    try
        vars[end] = eval(eq_expr)
        if !isfinite(sum(vars))
            return sample_and_eval_one_point(eq_expr, vars_info, vars, method; max_trials = max_trials - 1)
        else
            return vars
        end
    catch
        if max_trials > 0
            return sample_and_eval_one_point(eq_expr, vars_info, vars, method; max_trials = max_trials - 1)
        else
            throw("failed repeated resampling.")
        end
    end
end

function sample_dataset_incremental(
    val::OrderedDict;
    n_points   = 100,
    method     = "random",
    max_trials = 100,
    allowed_equation_elements = [
        :+, :-, :*, :/, :^,                         # binary operators
        :neg, :sin, :cos, :tanh, :sqrt, :exp, :log, # unary operators
        [Symbol("v$i") for i in 1:100]...],         # variables v1, ..., v100
    )

    eq_string = val["prp"]
    # make sure no malicious code
    for r in extract_operands_operators(eq_string)
        @assert r in allowed_equation_elements || r isa Number "$r not valid operator or operand"
    end

    # prepare data variable -> needs to be global for eval to wark
    vars_info = val["vars"]
    global vars = fill(0.0, length(vars_info))

    # replace the vi with vars[i]
    for i in 1:length(vars_info)-1
        eq_string = replace(eq_string, "v$i" => "vars[$i]")
    end
    eq_expr = Meta.parse(eq_string)

    return copy(reduce(
        hcat, copy(
            sample_and_eval_one_point(eq_expr, vars_info, vars, method; max_trials = max_trials)
        ) for v in 1:n_points
    )')
end

""" sample n_points between low and upp with method='random' or 'range' using a
    distr='log' or 'uni'. Values can be pow_neg='pos', 'neg' or 'pos_neg'. With
    integer=true, values are rounded after sampling.
"""
function sample_points(
    low::Float64,
    upp::Float64,
    n_points::Int64;
    method  = "random",
    distr   = "log",
    pos_neg = "pos_neg",
    integer = false
)
    @assert method  in ("range", "random")
    @assert distr   in ("uni", "log")
    @assert pos_neg in ("pos", "neg", "pos_neg")
    @assert low <= upp

    (n_points == 1 && method == "range") && @warn "sampling one point in mode='range' may not be sensible"

    if distr == "log"
        @assert sign(low) == sign(upp)       "for distr == 'log', low and upp must have the same sign"
        @assert !iszero(low) && !iszero(upp) "for distr == 'log', low and upp cannot == 0"
    end

    if distr == "log"
        low = log10(low)
        upp = log10(upp)
    end

    if method == "random"
        arr = rand(Uniform(low, upp), n_points)
    else
        arr = collect(range(low, upp, n_points))
        shuffle!(arr)
    end

    if distr == "log"
        arr .= 10.0.^arr
    end

    if pos_neg == "neg"
        arr .*= -1.0
    elseif pos_neg == "pos_neg"
        arr .*= rand((-1, 1), length(arr))
    end

    if integer
        arr .= round.(arr)
    end

    return arr
end

