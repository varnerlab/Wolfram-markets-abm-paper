include("Analyze-Following.jl")
using Test

@testset "market clusters and event boundary uncertainty" begin
    resamples=hcat(fill(1,2,1000),fill(2,2,1000))
    estimate=following_cluster_summary([0.,0.,1.,1.],[1,1,2,2],[1,2],resamples)
    @test estimate.estimate==0.5
    @test estimate.markets==2 && estimate.runs==4
    @test estimate.lower==0. && estimate.upper==1.
    zero=following_cluster_summary(zeros(4),[1,1,2,2],[1,2],resamples;probability=true)
    @test zero.upper≈1-sqrt(0.05)
    @test zero.interval=="one_sided_exact_cluster_boundary_95"
    one=following_cluster_summary(ones(4),[1,1,2,2],[1,2],resamples;probability=true)
    @test one.lower≈sqrt(0.05)
    same=following_cluster_summary(zeros(4),[1,1,2,2],[1,2],resamples;binary_contrast=true)
    @test same.lower≈-(1-sqrt(0.05)) && same.upper≈1-sqrt(0.05)
    perfect=following_cluster_summary(ones(4),[1,1,2,2],[1,2],resamples;binary_contrast=true)
    @test perfect.lower≈1-2(1-sqrt(0.05)) && perfect.upper==1
    absent=following_cluster_summary(fill(NaN,4),[1,1,2,2],[1,2],resamples)
    @test isnan(absent.estimate) && absent.valid_runs==0 && absent.valid_bootstraps==0
end
