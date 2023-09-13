

import AdvancedLayoutCalculator.Calculators: selectsolutionindexes, BestScoresSelector, RouletteSelector
@testset "solution indexes" begin
    rng = Xoshiro(5)
    scores = rand(rng, 20)
    sortedscoreinds = sortperm(scores)
    println(scores)
    println(sortedscoreinds)
    arsinds = selectsolutionindexes(rng, RouletteSelector(), scores, 65, 100)
    println(arsinds)
    bssinds = selectsolutionindexes(rng, BestScoresSelector(), scores, 65, 100)
    println(bssinds)
    shouldnotappear = sortedscoreinds[8:end]
    for n in shouldnotappear
        @test length(filter(x -> (n in x), bssinds)) == 0
    end

    bssinds = selectsolutionindexes(rng, BestScoresSelector(), scores, 30, 100)
    println(bssinds)
    shouldnotappear = sortedscoreinds[7 + Int(ceil((20 - 7)*0.25))+1:end]
    for n in shouldnotappear
        @test length(filter(x -> (n in x), bssinds)) == 0
    end


    # visual testing purposes
    scores = sort!(rand(rng, 20))
    sortedscoreinds = sortperm(scores)
    println(sortedscoreinds)
    bssinds = selectsolutionindexes(rng, BestScoresSelector(xs=[0, 0.25, 0.5, 0.75, 1.0], ys=[0.5, 0.25, 0.5, 0.0, 0.0]), scores, 30, 100)
    println(bssinds)



end
println("exiting smalling genetic tests early")
# exit()
rng = Xoshiro(2)
@testset "no crossover" begin
    @testset "Small genetic layout calc test, immovable layer switches" begin
        cc = CalculatorConfig(populationsize=50, crossoverweight=0, maxiter=10)
        sf = BasicScoreFunction()
        glc = GeneticLayoutCalculator(cc, sf)
        ls = LayerSwitchmap([KeyLocation(), KeyLocation(1, (1, 1))])
        el = EffortLayer([[0.5, 0.1, 0.3]])
        km = Keymap([[Key(_LS, false), Key(), Key()]], [[Key(_LS, false), Key(), Key()]], layerswitches=ls, effortlayer=el)
        fh = SimpleFrequencyHolder(Dict{Ngram, Float32}(Ngram(_A) => 1, Ngram(_E) => 2, Ngram(_O) => 0.5, Ngram(_U) => 0.25))
        km, s1, s2, s3 = calculatelayout(rng, glc, km, fh; checkpointdir=nothing)
        kmsoln = Keymap(Layer([[Key(_LS, false), Key(_E), Key(_A)]]), Layer([[Key(_LS, false), Key(_O), Key(_U)]]); layerswitches=ls, effortlayer=el)
        println("expected final score $(first(calculatescore(sf, kmsoln, fh, getngrams(fh))))")
        @test km == kmsoln
        println(s1)
        println(s2)
        println(s3)
    end

    @testset "Small genetic layout calc test, movable layer switches" begin
        cc = CalculatorConfig(populationsize=250, crossoverweight=0, maxiter=2, earlystopping = f(x, y, z) = return false)
        sf = BasicScoreFunction()
        glc = GeneticLayoutCalculator(cc, sf)
        ls = LayerSwitchmap([KeyLocation(), KeyLocation(1, (1, 2))])
        el = EffortLayer([[0.5, 0.1, 0.3, 0.2]])
        km = Keymap(Layer([[Key(), Key(_LS), Key(), Key()]]), Layer([[Key(), Key(_LS), Key(), Key()]]), layerswitches=ls, effortlayer=el)
        fh = SimpleFrequencyHolder(Dict{Ngram, Float32}(Ngram(_A) => 1, Ngram(_E) => 2, Ngram(_O) => 0.5, Ngram(_U) => 0.25))
        km, s1, s2, s3 = calculatelayout(rng, glc, km, fh; checkpointdir=nothing)
        println(km)
        outputscore = s2[end]
        ls2 = LayerSwitchmap([KeyLocation(), KeyLocation(1, (1, 1))])
        kmsoln = Keymap(Layer([[Key(_LS), Key(_E), Key(_O), Key(_A)]]), Layer([[Key(_LS), Key(_U), Key(), Key()]]), layerswitches=ls2, effortlayer=el)
        println(kmsoln)
        expectedscore = first(calculatescore(sf, kmsoln, fh, getngrams(fh)))
        println("expected final score $expectedscore")
        # @test round(outputscore, digits=6) == round(expectedscore, digits=6) # threads mess up rng so it won't always get the expected result
        println(s1)
        println(s2)
        println(s3)
    end
end


import AdvancedLayoutCalculator.Calculators: _movelayerswitchesfrom1to2!, getbasekmpermutation, getkmpermutation, crossover!

rng = Xoshiro(1)
@testset "small crossover" begin
    @testset "moving layer switches from km1 to km2" begin
        ls1 = LayerSwitchmap(KeyLocation(), KeyLocation(1, (1, 1)), KeyLocation(2, (1, 4)))
        ls2 = LayerSwitchmap(KeyLocation(), KeyLocation(1, (1, 3)), KeyLocation(2, (1, 2)))
        km1 = Keymap(
            Layer([[Key(_LS), Key(_E), Key(_D),  Key(_X)]]), 
            Layer([[Key(_LS), Key(_B), Key(_C), Key(_LS)]]),
            Layer([[Key(_Y), Key(_A), Key(_F), Key(_LS)]]),
            layerswitches = ls1
            )
        km2 = Keymap(
            Layer([[Key(_E), Key(_O), Key(_LS), Key(_T)]]),
            Layer([[Key(_G), Key(_LS), Key(_LS), Key(_U)]]),
            Layer([[Key(_M), Key(_LS), Key(_N), Key(_S)]]),
            layerswitches = ls2
        )
        _movelayerswitchesfrom1to2!(km1, km2)
        @test value(km2[KeyLocation(1, (1, 1))]) == _LS
        @test value(km2[KeyLocation(2, (1, 1))]) == _LS
        @test value(km2[KeyLocation(1, (1, 3))]) == _E
        @test value(km2[KeyLocation(2, (1, 3))]) == _G
        @test value(km2[KeyLocation(2, (1, 4))]) == _LS
        @test value(km2[KeyLocation(3, (1, 4))]) == _LS
        @test value(km2[KeyLocation(2, (1, 2))]) == _U
        @test value(km2[KeyLocation(3, (1, 2))]) == _S
    end

    @testset "permutation stuff" begin
        ls1 = LayerSwitchmap(KeyLocation(), KeyLocation(1, (1, 1)))
        ls2 = LayerSwitchmap(KeyLocation(), KeyLocation(1, (1, 3)))
        km1 = Keymap(
            Layer([[Key(_LS), Key(_E), Key()]]), 
            Layer([[Key(_LS), Key(_A), Key()]]),
            layerswitches =
             ls1
            )
        km2 = Keymap(
            Layer([[Key(_E), Key(), Key(_LS)]]),
            Layer([[Key(_A), Key(_E), Key(_LS)]]),
            layerswitches = ls2
        )
        _movelayerswitchesfrom1to2!(km1, km2)
        println("placeholder small test for moving layer switches")
        # println(km1)
        # println(km2)
        bp = getbasekmpermutation(km1, km2)

        p1, _ = getkmpermutation(km1, bp)
        println("placeholder small test for getting permutation")
        # println(p1.d)
        # println(p1)

        
        @testset "crossover" begin
            test = crossover!(rng, km1, km2)
            println("placeholder small test for crossover")
            # println(test)
        end
    end
end
