
function extract_by_name(name, main_bench)
    ind = findfirst(k -> main_bench[k]["name"] == name, main_bench.keys)
    if isnothing(ind)
        throw("$name not in srsd bench")
        return nothing
    end
    return main_bench.keys[ind], main_bench.vals[ind]
end

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

function sample_points(low::Float64, upp::Float64, n_points::Int64; method="random", distr="log", pos_neg="pos_neg", integer=false)
    @assert method  in ("range", "random")
    @assert distr   in ("uni", "log")
    @assert pos_neg in ("pos", "neg", "pos_neg")

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

function count_expr(expr)
    !(expr isa Expr) && return 1
    return sum(count_expr(a) for a in  expr.args)
end

