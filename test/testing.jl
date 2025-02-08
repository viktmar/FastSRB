

using Test
using Statistics

include("src/SRSD.jl")

using .SRSD

@testset "test_sample_points" begin

    # Test uniform distribution, range method, positive numbers
    arr = SRSD.sample_points(1.0, 10.0, 50, method="range", distr="uni", pos_neg="pos", integer=false)
    @test length(arr) == 50
    @test !issorted(arr)
    @test all(1.0 .<= arr .<= 10.0)
    @test isapprox(median(arr), 5.5, atol=1.0)

    # Test uniform distribution, random method, positive and negative numbers
    arr = SRSD.sample_points(0.0, 10.0, 50, method="random", distr="uni", pos_neg="pos_neg", integer=false)
    @test length(arr) == 50
    @test !issorted(arr)
    @test all(abs.(arr) .<= 10.0)
    @test any(>(0), arr) && any(<(0), arr)
    @test isapprox(median(arr), 0.0, atol=1.0)

    # Test log distribution, range method
    arr = SRSD.sample_points(1.0, 100.0, 50, method="range", distr="log", pos_neg="pos", integer=false)
    @test length(arr) == 50
    @test !issorted(arr)
    @test all(1.0 .<= arr .<= 100.0)
    @test isapprox(median(arr), 10, atol=5)

    # Test log distribution, random method
    arr = SRSD.sample_points(1.0, 100.0, 50, method="random", distr="log", pos_neg="pos", integer=false)
    @test length(arr) == 50
    @test !issorted(arr)
    @test all(1.0 .<= arr .<= 100.0)
    @test isapprox(median(arr), 10, atol=5)

    # Test integer rounding
    arr = SRSD.sample_points(1.0, 10.0, 50, method="random", distr="uni", pos_neg="pos", integer=true)
    @test all(v -> v % 1 == 0, arr)
    @test length(arr) == 50

    # Test negative numbers
    arr = SRSD.sample_points(1.0, 10.0, 5, method="random", distr="uni", pos_neg="neg", integer=false)
    @test all(arr .<= -1.0)

    # Test assertion for mismatched log limits
    @test_throws AssertionError SRSD.sample_points(-1.0, 10.0, 5, method="random", distr="log", pos_neg="pos", integer=false)

    # Test assertion for invalid method
    @test_throws AssertionError SRSD.sample_points(1.0, 10.0, 5, method="invalid", distr="uni", pos_neg="pos", integer=false)

    # Test assertion for invalid distribution
    @test_throws AssertionError SRSD.sample_points(1.0, 10.0, 5, method="random", distr="invalid", pos_neg="pos", integer=false)

    # Test assertion for invalid pos_neg option
    @test_throws AssertionError SRSD.sample_points(1.0, 10.0, 5, method="random", distr="uni", pos_neg="invalid", integer=false)
end

