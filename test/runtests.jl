
using Test
using Statistics: Uniform
using OrderedCollections: OrderedDict
using Random: shuffle!
using SRSD

# Comprehensive test suite
@testset "SRSD.jl Comprehensive Tests" begin

    ### round_equation_string
    @testset "round_equation_string" begin
        # Typical string inputs
        @test round_equation_string("2.3456 + 3.14159 * x") == "2.35 + 3.14x"
        @test round_equation_string("1.23456", sigdigits=2) == "1.2"
        @test round_equation_string("sin(3.14159)", sigdigits=3) == "sin(3.14)"

        # Expr inputs
        @test string(round_equation_string(:(1.2345 + sin(x)))) == "1.23 + sin(x)"
        @test string(round_equation_string(:(2.56789 * x))) == "2.57x"

        # Number inputs
        @test round_equation_string(5.6789) ≈ 5.68
        @test round_equation_string(0.001234, sigdigits=2) ≈ 0.0012
        @test round_equation_string(-3.14159) ≈ -3.14

        # Edge cases
        @test round_equation_string("x") == "x"  # No numbers
        @test round_equation_string(:x) === :x  # Symbol
        @test round_equation_string("1.0 + 2.0") == "1.0 + 2.0"  # Exact integers

        # Invalid inputs
        @test round_equation_string(nothing) === nothing  # Non-supported type
    end

    ### get_nary_compl
    @testset "get_nary_compl" begin
        # Typical cases
        @test get_nary_compl("a + b + c") == 4  # :+, :a, :b, :c
        @test get_nary_compl("2 * x * y") == 4  # :*, 2, :x, :y
        @test get_nary_compl("sin(cos(x))") == 3  # :sin, :cos, :x

        # Single values
        @test get_nary_compl(:x) == 1
        @test get_nary_compl(42) == 1
        @test get_nary_compl("a") == 1

        # Edge cases
        @test get_nary_compl("") == 1  # Empty string
        @test get_nary_compl(" ") == 1  # Whitespace
        @test get_nary_compl(:(+)) == 1  # Operator alone

        # Nested and complex
        @test get_nary_compl("a + b * c + d") == 6  # :+, :a, :*, :b, :c, :d
    end

    ### get_binary_compl
    @testset "get_binary_compl" begin
        # Typical cases
        @test get_binary_compl("a + b + c") == 5  # [:(+), :(+), :a, :b, :c]
        @test get_binary_compl("2 * x") == 3  # [:(*), 2, :x]
        @test get_binary_compl("sin(x)") == 2  # [:sin, :x]

        # Single values
        @test get_binary_compl(:x) == 1
        @test get_binary_compl(1//2) == 1
        @test get_binary_compl(42.0) == 1

        # Complex expressions
        @test get_binary_compl("a + b * c") == 5  # [:(+), :a, :(*), :b, :c]
        @test get_binary_compl("sin(cos(x)) + y") == 5  # [:(+), :sin, :cos, :x, :y]

        # Edge cases
        @test get_binary_compl("") == 1  # Empty string
        @test get_binary_compl(" ") == 1  # Whitespace
    end

    ### expr_to_prefix
    @testset "expr_to_prefix" begin
        # Typical cases
        @test expr_to_prefix(:(a + b + c)) == [:+, :+, :a, :b, :c]
        @test expr_to_prefix(:(2 * x + 3)) == [:+, :*, 2, :x, 3]
        @test expr_to_prefix(:(sin(x))) == [:sin, :x]

        # Single values
        @test expr_to_prefix(:x) == [:x]
        @test expr_to_prefix(1//2) == [0.5]
        @test expr_to_prefix(42) == [42]

        # Complex expressions
        @test expr_to_prefix(:(a + b * c)) == [:+, :a, :*, :b, :c]
        @test expr_to_prefix(:(sin(cos(x)))) == [:sin, :cos, :x]

        # Edge cases
        @test expr_to_prefix(:(+)) == [:+]  # Lone operator
    end

    ### extract_operands_operators
    @testset "extract_operands_operators" begin
        # Typical cases
        @test extract_operands_operators("2 + sin(x)") == [:+, 2, :sin, :x]
        @test extract_operands_operators(:(3 * v1 - 4)) == [:-, :*, 3, :v1, 4]
        @test extract_operands_operators("a + b * c") == [:+, :a, :*, :b, :c]

        # Single values
        @test extract_operands_operators(:x) == [:x]
        @test extract_operands_operators(42) == [42]

        # Nested expressions
        @test extract_operands_operators("sin(cos(x))") == [:sin, :cos, :x]
        @test extract_operands_operators("a + b + c * d") == [:+, :a, :b, :*, :c, :d]
    end

    ### string_expl
    @testset "string_expl" begin
        # Typical cases
        @test string_expl("2v1") == "(2*v1)"
        @test string_expl("sin(x)") == "sin(x)"
        @test string_expl("a + b * c") == "(a+(b*c))"

        # Expr inputs
        @test string_expl(:(2 + 3 * x)) == "(2+(3*x))"
        @test string_expl(:(sin(2x))) == "sin((2*x))"

        # Single values
        @test string_expl(:x) == "x"
        @test string_expl("v1") == "v1"

        @test string_expl("2*x") == "(2*x)"  # Already explicit
    end

    ### sample_dataset (eq_id)
    @testset "sample_dataset (eq_id)" begin
        # Typical case
        result = sample_dataset("II.38.3", n_points=3)
        @test size(result) == (3, 5)
        @test all(isfinite, result)
        @test all(isapprox.(((result[:, 1].*result[:, 2].*result[:, 3])./result[:, 4]), result[:, 5], atol=1e-10))

        # Incremental sampling
        result = sample_dataset("II.38.3", n_points=3, incremental=true)
        @test size(result) == (3, 5)
        @test all(isfinite, result)
        @test all(isapprox.(((result[:, 1].*result[:, 2].*result[:, 3])./result[:, 4]), result[:, 5], atol=1e-10))

        # Error cases
        @test_throws AssertionError sample_dataset("invalid_id")  # Non-existent eq_id
        @test_throws AssertionError sample_dataset("II.38.3", n_points=0)  # Invalid n_points
    end

    ### sample_dataset (OrderedDict)
    @testset "sample_dataset (OrderedDict)" begin
        val = OrderedDict(
            "prp" => "v1 + sin(v2)",
            "vars" => OrderedDict(
                "v1" => OrderedDict("sample_type" => ("uni", "pos"), "sample_range" => (0.0, 1.0)),
                "v2" => OrderedDict("sample_type" => ("uni", "pos_neg"), "sample_range" => (-1.0, 1.0))
            )
        )

        # Typical case
        result = sample_dataset(val, n_points=3)
        @test size(result) == (3, 3)
        @test all(isfinite, result)
        @test all(0 .<= result[:, 1] .<= 1)
        @test all(-1 .<= result[:, 2] .<= 1)
        @test all(isapprox.(result[:, 3], result[:, 1] .+ sin.(result[:, 2]), atol=1e-10))

        # Invalid equation
        val_invalid = deepcopy(val)
        val_invalid["prp"] = "v1 + invalid_func(v2)"
        @test_throws AssertionError sample_dataset(val_invalid)

        # Max trials exhaustion
        val_div = OrderedDict(
            "prp" => "sqrt(v1)",
            "vars" => OrderedDict(
                "v1" => OrderedDict("sample_type" => ("uni", "pos"), "sample_range" => (-0.1, 0.0))
            )
        )
        # Edge cases
        @test_throws AssertionError sample_dataset(val_div, n_points=-1)  # Negative points
        @test_throws ErrorException sample_dataset(val_div, n_points=5)  # Negative points
    end

    ### sample_and_eval_one_point
    @testset "sample_and_eval_one_point" begin
        eq_expr = Meta.parse("data[1] + sin(data[2])")
        vars_info = Dict(
            "v1" => Dict("sample_type" => ("uni", "pos"), "sample_range" => (0.0, 1.0)),
            "v2" => Dict("sample_type" => ("uni", "pos_neg"), "sample_range" => (-1.0, 1.0))
        )
        n_vars = 2

        # Typical case
        result = sample_and_eval_one_point(eq_expr, vars_info, n_vars, "random")
        @test length(result) == 3
        @test 0 <= result[1] <= 1
        @test -1 <= result[2] <= 1
        @test isapprox(result[3], result[1] + sin(result[2]), atol=1e-10) # TODO: fails

        # Integer sampling
        vars_info_int = Dict(
            "v1" => Dict("sample_type" => ("int", "pos"), "sample_range" => (1.0, 5.0)),
            "v2" => Dict("sample_type" => ("uni", "pos"), "sample_range" => (0.0, 1.0))
        )
        n_vars = 2
        result_int = sample_and_eval_one_point(eq_expr, vars_info_int, n_vars, "random")
        @test result_int[1] in 1:5
        @test isinteger(result_int[1])

        # Max trials exhaustion
        eq_expr_fail = Meta.parse("sqrt(data[1])")
        vars_info_fail = Dict(
            "v1" => Dict("sample_type" => ("uni", "pos"), "sample_range" => (-0.1, 0.0))
        )
        n_vars = 1
        @test_throws ErrorException sample_and_eval_one_point(eq_expr_fail, vars_info_fail, n_vars, "random", max_trials=1)

        # Edge cases
        @test_throws KeyError sample_and_eval_one_point(eq_expr, Dict(), n_vars, "random")  # Empty vars_info
    end

    ### sample_dataset_incremental
    @testset "sample_dataset_incremental" begin
        val = OrderedDict(
            "prp" => "v1 * cos(v2)",
            "vars" => OrderedDict(
                "v1" => OrderedDict("sample_type" => ("uni", "pos"), "sample_range" => (0.0, 1.0)),
                "v2" => OrderedDict("sample_type" => ("uni", "pos"), "sample_range" => (-1.0, 0.0))
            )
        )

        # Typical case
        result = sample_dataset_incremental(val, n_points=3)
        @test size(result) == (3, 3)  # 2 vars + 1 output, 3 points
        @test all(isfinite, result)
        @test all(0 .<= result[:, 1] .<= 1)
        @test all(-1 .<= result[:, 2] .<= 0)
        @test isapprox(result[:, 3], result[:, 1] .* cos.(result[:, 2]), atol=1e-10) # TODO: fails

        # Invalid variable count
        val_invalid = deepcopy(val)
        val_invalid["vars"] = OrderedDict("v1" => val["vars"]["v1"])
        @test_throws AssertionError sample_dataset_incremental(val_invalid)

        # Edge cases
        @test_throws AssertionError sample_dataset_incremental(val, n_points=0)  # Zero points
    end

    ### sample_points
    @testset "sample_points" begin
        # Random uniform, pos
        points = sample_points(0.0, 10.0, 500, distr="uni", pos_neg="pos_neg")
        @test length(points) == 500
        @test !all(points .> 0)
        @test all(0 .<= abs.(points) .<= 10)

        # Logarithmic, pos_neg
        points = sample_points(1.0, 100.0, 500, distr="log", pos_neg="pos_neg")
        @test !all(1 .<= points .<= 100)
        @test all(1 .<= abs.(points) .<= 100)

        # Range method
        points = sample_points(0.0, 10.0, 4, method="range", distr="uni", pos_neg="pos")
        @test length(points) == 4
        @test all(0 .<= points .<= 10)
        @test length(unique(round.(diff(sort(points)), sigdigits=5))) == 1

        # Integer sampling
        points = sample_points(1.0, 5.0, 3, integer=true, pos_neg="pos")
        @test all(isinteger, points)
        @test all(1 .<= points .<= 5)

        # Single point
        points = sample_points(5.0, 5.0, 1)
        @test points == [5.0]

        # Error cases
        @test_throws AssertionError sample_points(10.0, 1.0, 5)  # low > upp
        @test_throws AssertionError sample_points(0.0, 10.0, 5, distr="log")  # log with zero
        @test_throws AssertionError sample_points(1.0, -10.0, 5, distr="log")  # different signs
        @test_throws AssertionError sample_points(1.0, 10.0, 5, method="invalid")
        @test_throws AssertionError sample_points(1.0, 10.0, 5, pos_neg="invalid")
        @test_throws AssertionError sample_points(1.0, 10.0, 0)  # Zero points
    end
end
