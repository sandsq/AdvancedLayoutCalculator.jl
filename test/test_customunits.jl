@testset "units from Unitful" begin

    @test ustrip(2u"ku") == 2
    @test uconvert(u"mm", 1u"ku") == 13u"mm"
    @test unit(3.2u"ku") == u"ku"
    
end