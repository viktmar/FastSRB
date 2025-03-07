
# ==================================================================================================
# helpers
# ==================================================================================================
# operator definitions # ---------------------------------------------------------------------------
neg(x) = -x

# various equation string processing #  ------------------------------------------------------------
"""
    round_equation_string(str::String; sigdigits=3)
    round_equation_string(expr::Expr; sigdigits=3)

Round all numbers in an equation string or expression to a specified number of significant
digits and return the result as a string.

# Arguments
- `str::String`: A string representation of an equation to parse and round
- `expr::Expr`: A parsed Julia expression to process
- `sigdigits=3`: Number of significant digits for rounding (default: 3)

# Returns
- For `String` input: A string with numbers rounded
- For `Expr` input: The modified expression with rounded numbers

# Examples
```julia
SRSD.round_equation_string("2.3456 + 3.14159 * x") # Returns "2.35 + 3.14x"
SRSD.round_equation_string(:(1.2345 + sin(x)))     # Returns modified Expr, converts to "1.23 + sin(x)"
```
"""
round_equation_string(str::String; sigdigits=3) = string(round_equation_string(Meta.parse(str), sigdigits=sigdigits))
round_equation_string(num::Number; sigdigits=3) = round(num, sigdigits=sigdigits)
round_equation_string(else_; sigdigits=3) = else_

function round_equation_string(expr::Expr; sigdigits=3)
    map!(s -> round_equation_string(s, sigdigits=sigdigits), expr.args, expr.args)
    expr
end

"""
    get_nary_compl(expr::String)
    get_nary_compl(expr)

Determine the n-ary complexity of an expression by recursively counting all elements
in its expression tree, preserving n-ary structure.

# Arguments
- `expr::String`: A string representation of an expression to parse and analyze
- `expr`: A Julia expression, number, or symbol

# Returns
An integer representing the total number of elements (operators and operands) in
the n-ary expression tree.

# Examples
```julia
SRSD.get_nary_compl("a + b + c") # Returns 4 (from :(+), :a, :b, :c)
SRSD.get_nary_compl("2 * x")     # Returns 3 (from :(*), 2, :x)
SRSD.get_nary_compl(:x)          # Returns 1 (single symbol)
```
"""
get_nary_compl(expr::String) = get_nary_compl(Meta.parse(expr))

function get_nary_compl(expr)
    !(expr isa Expr) && return 1
    return sum(get_nary_compl(a) for a in  expr.args)
end

"""
    get_binary_compl(expr::String)
    get_binary_compl(expr)

Determine the binary complexity of an expression by converting it to a binary prefix
array and counting its elements.

# Arguments
- `expr::String`: A string representation of an expression to parse and analyze
- `expr`: A Julia expression, number, or symbol

# Returns
An integer representing the number of elements in the binary prefix representation
of the expression.

# Examples
```julia
SRSD.get_binary_compl("a + b + c") # Returns 5 (from [:(+), :(+), :a, :b, :c])
SRSD.get_binary_compl("2 * x")     # Returns 3 (from [:(*), 2, :x])
SRSD.get_binary_compl(:x)          # Returns 1 (from [:x])
```
"""
get_binary_compl(expr::String) = get_binary_compl(Meta.parse(expr))
get_binary_compl(expr)         = length(expr_to_prefix(expr))

"""
    expr_to_prefix(expr::Expr)

Convert an n-ary Julia expression into a binary prefix array representation.

# Arguments
- `expr::Expr`: A Julia expression with n-ary operations

# Returns
A vector representing the expression in prefix notation, where n-ary operations are
converted to repeated binary operations.

# Examples
```julia
SRSD.expr_to_prefix(:(a + b + c)) # Returns [:(+), :(+), :a, :b, :c]
SRSD.expr_to_prefix(:(2 * x + 3)) # Returns [:(+), :(*), 2, :x, 3]
SRSD.expr_to_prefix(1//2)         # Returns [0.5]
SRSD.expr_to_prefix(:x)           # Returns [:x]
```
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

"""
    extract_operands_operators(expr::String)
    extract_operands_operators(expr)

Extract all operators and operands from an equation or expression to verify its contents
before evaluation, helping prevent malicious code execution.

# Arguments
- `expr::String`: A string representation of an equation to parse and analyze
- `expr`: An expression, number, or symbol to process

# Returns
A vector containing all operators (as Symbols) and operands (as Numbers or Symbols) found
in the expression.

# Examples
```julia
SRSD.extract_operands_operators("2 + sin(x)")  # Returns [:+, 2, :sin, :x]
SRSD.extract_operands_operators(:(3 * v1 - 4)) # Returns [:-, :*, 3, :v1, 4]
```
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

"""
    string_expl(e::String)
    string_expl(e::Expr)

Convert an expression or string into a fully explicit string representation, adding
operators where implied (e.g., converting `2v1` to `2 * v1`).

# Arguments
- `e::String`: A string representation of an expression to parse and convert
- `e::Expr`: A parsed Julia expression (from Meta.parse)

# Returns
A string with all operators explicitly included.

# Examples
```julia
SRSD.string_expl("2v1")        # Returns "(2 * v1)"
SRSD.string_expl(:(sin(x)))    # Returns "sin(x)"
SRSD.string_expl(:(2 + 3 * x)) # Returns "(2 + (3 * x))"
```
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
"""
    sample_dataset(eq_id::String; n_points=100, method="random", max_trials=100,
                      allowed_equation_elements=[...], incremental=false)

Sample a dataset from an equation specified by `eq_id` in the equation collection YAML file.
Extracts the equation data and applies appropriate sampling functions based on the specified parameters.

# Arguments
- `eq_id::String`: The identifier of the equation to sample from the MAIN_BENCH collection
- `n_points=100`: Number of data points to sample
- `method="random"`: Sampling method ("random" or "range")
- `max_trials=100`: Maximum number of sampling attempts
- `allowed_equation_elements=[...]` : List of permitted equation elements including:
  - Binary operators: +, -, *, /, ^
  - Unary operators: neg, sin, cos, tanh, sqrt, exp, log
  - Variables: v1 through v100
- `incremental=false`: If true, uses incremental sampling approach

# Returns
A sampled dataset based on the specified equation and parameters.

# Examples
```julia
# Basic random sampling
SRSD.sample_dataset("II.38.3", n_points=50)

# Range sampling with specific elements
SRSD.sample_dataset("II.38.3", method="range")
```
"""
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
    @assert n_points >= 1

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

"""
    sample_dataset(val::OrderedDict; n_points=100, method="random", max_trials=100,
                      allowed_equation_elements=[...])

Sample a dataset from an equation specified in an OrderedDict, generating independent variables
and calculating the dependent variable based on the equation string.

# Arguments
- `val::OrderedDict`: Dictionary containing equation data with "prp" (equation string) and "vars" (variable info)
- `n_points=100`: Number of data points to sample
- `method="random"`: Sampling method ("random" or "range")
- `max_trials=100`: Maximum number of resampling attempts if errors occur
- `allowed_equation_elements=[...]` : List of permitted equation elements including:
  - Binary operators: +, -, *, /, ^
  - Unary operators: neg, sin, cos, tanh, sqrt, exp, log
  - Variables: v1 through v100

# Returns
A matrix of size (n_points × n_variables) containing sampled independent variables and
calculated dependent variable.

# Behavior
1. Validates equation elements against allowed set
2. Samples independent variables based on specified distributions and ranges
3. Evaluates equation to compute dependent variable
4. Retries on failure up to max_trials times
5. Ensures all returned values are finite

# Examples
```julia
val = OrderedDict(
    "prp" => "v1 + sin(v2)",
    "vars" => OrderedDict(
        "v1" => OrderedDict(
            "sample_type"  => ("uni", "pos"),
            "sample_range" => (0.0, 1.0)
        ),
        "v2" => OrderedDict(
            "sample_type"  => ("uni", "pos_neg"),
            "sample_range" => (-1.0, 1.0)
        )
    )
)
data = SRSD.sample_dataset(val, n_points = 50)
```
"""
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
    @assert n_points >= 1
    eq_string = val["prp"]
    # make sure no malicious code
    for r in extract_operands_operators(eq_string)
        @assert r in allowed_equation_elements || r isa Number "$r not valid operator or operand"
    end

    # prepare data variable -> needs to be global for eval to wark
    n_vars = maximum(parse(Int, m.captures[1]) for m in eachmatch(r"v(\d+)", eq_string))
    vars_info = val["vars"]
    @assert length(vars_info) in (n_vars, n_vars+1) "more variables than provided in 'vars'"

    # replace the vi with data[:, i]
    for i in 1:n_vars
        eq_string = replace(eq_string, "v$i" => "data[:, $i]")
    end
    eq_string = "@. " * eq_string
    eq_expr = Meta.parse(eq_string)

    # sample independet variables # ----------------------------------------------------------------
    global data = zeros(n_points, n_vars+1)
    for i in 1:n_vars
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
            sample_dataset(
                val;
                n_points   = n_points,
                method     = method,
                max_trials = max_trials - 1,
                allowed_equation_elements = allowed_equation_elements
            )
        else
            throw(ErrorException("cannot sample data. keeps raising exceptions. try setting incremental=true"))
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

"""
    sample_and_eval_one_point(eq_expr, vars_info, n_vars, method; max_trials=100)

Sample and evaluate a single point for an equation, including independent variables and
the dependent variable computed from the given expression.

# Arguments
- `eq_expr`: Parsed expression (from Meta.parse) representing the equation
- `vars_info`: Dictionary containing variable sampling specifications
- `n_vars`: integer number of variables
- `method`: Sampling method ("random" or "range") passed to `sample_points`
- `max_trials=100`: Maximum number of resampling attempts if evaluation fails

# Returns
An array with sampled independent variables in and the calculated dependend one
at the last index.
# Behavior
1. Samples one value for each independent variable using `sample_points`
2. Evaluates `eq_expr` to compute the dependent variable
3. Retries on evaluation errors or non-finite results up to `max_trials` times

# Examples
```julia
eq_expr = Meta.parse("data[1] + sin(data[2])")
vars_info = Dict(
    "v1" => Dict("sample_type" => ("uni", "pos"), "sample_range" => (0.0, 1.0)),
    "v2" => Dict("sample_type" => ("uni", "pos_neg"), "sample_range" => (-.01, 1.0))
)
n_vars = 2
result = SRSD.sample_and_eval_one_point(eq_expr, vars_info, n_vars, "random")
```
"""
function sample_and_eval_one_point(eq_expr, vars_info, n_vars, method; max_trials=100)
    # sample one set of independet variables
    global data = zeros(n_vars+1)
    data[1:end-1] .= map(1:n_vars) do i
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
        data[end] = eval(eq_expr)
        if !isfinite(sum(data))
            return sample_and_eval_one_point(eq_expr, vars_info, n_vars, method; max_trials = max_trials - 1)
        else
            return copy(data)
        end
    catch
        if max_trials > 0
            return sample_and_eval_one_point(eq_expr, vars_info, n_vars, method; max_trials = max_trials - 1)
        else
            throw(ErrorException("failed repeated resampling."))
        end
    end
end

"""
    sample_dataset_incremental(val::OrderedDict; n_points=100, method="random", max_trials=100,
                              allowed_equation_elements=[...])

Sample a dataset incrementally, one point at a time, from an equation specified in an OrderedDict.
Evaluates the equation for each point independently rather than vectorized.

# Arguments
- `val::OrderedDict`: Dictionary containing equation data with "prp" (equation string) and "vars" (variable info)
- `n_points=100`: Number of data points to sample
- `method="random"`: Sampling method ("random" or "range")
- `max_trials=100`: Maximum number of sampling attempts per point
- `allowed_equation_elements=[...]` : List of permitted equation elements including:
  - Binary operators: +, -, *, /, ^
  - Unary operators: neg, sin, cos, tanh, sqrt, exp, log
  - Variables: v1 through v100

# Returns
A matrix of size (n_vars+1 × n_points) containing sampled independent variables and
calculated dependent variable, where each column represents one sampled point.

# Behavior
1. Validates equation elements against allowed set
2. Determines number of variables from equation string
3. Samples and evaluates one point at a time using `sample_and_eval_one_point`
4. Combines results horizontally into final matrix

# Examples
```julia
val = OrderedDict(
    "prp" => "v1 * cos(v2)",
    "vars" => OrderedDict(
        "v1" => Dict("sample_type" => ("uni", "pos"), "sample_range" => (0.0, 1.0)),
        "v2" => Dict("sample_type" => ("uni", "pos_neg"), "sample_range" => (-1.0, 1.0))
    )
)
data = SRSD.sample_dataset_incremental(val, n_points=20)
```
"""
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
    @assert n_points >= 1

    eq_string = val["prp"]
    # make sure no malicious code
    for r in extract_operands_operators(eq_string)
        @assert r in allowed_equation_elements || r isa Number "$r not valid operator or operand"
    end

    # prepare data variable -> needs to be global for eval to wark
    n_vars = maximum(parse(Int, m.captures[1]) for m in eachmatch(r"v(\d+)", eq_string))
    vars_info = val["vars"]
    @assert length(vars_info) in (n_vars, n_vars+1) "more variables than provided in 'vars'"

    # replace the vi with data[i]
    for i in 1:n_vars
        eq_string = replace(eq_string, "v$i" => "data[$i]")
    end
    eq_expr = Meta.parse(eq_string)

    return copy(reduce(
        hcat, copy(
            sample_and_eval_one_point(eq_expr, vars_info, n_vars, method; max_trials = max_trials)
        ) for v in 1:n_points
    )')
end

"""
    sample_points(low::Float64, upp::Float64, n_points::Int64; method="random",
                 distr="log", pos_neg="pos_neg", integer=false)

Sample `n_points` values between `low` and `upp` using either random or range-based sampling,
with optional logarithmic distribution and sign control.

# Arguments
- `low::Number`: Lower bound of sampling range
- `upp::Number`: Upper bound of sampling range
- `n_points::Int64`: Number of points to sample
- `method="random"`: Sampling method ("random" for uniform random, "range" for evenly spaced)
- `distr="log"`: Distribution type ("log" for logarithmic, "uni" for uniform)
- `pos_neg="pos_neg"`: Sign control ("pos" for positive, "neg" for negative, "pos_neg" for both)
- `integer=false`: If true, rounds sampled values to nearest integers

# Returns
A vector of length `n_points` containing sampled values.

# Examples
```julia
# Random logarithmic sampling, mixed signs
points = SRSD.sample_points(1.0, 100.0, 5, distr="log", pos_neg="pos_neg")

# Evenly spaced uniform sampling, positive only
points = SRSD.sample_points(0.0, 10.0, 4, method="range", distr="uni", pos_neg="pos")
```
"""
function sample_points(
    low::Number,
    upp::Number,
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
    @assert n_points >= 1

    low = Float64(low)
    upp = Float64(upp)

    if low == upp
        return [upp for _ in 1:n_points]
    end

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

