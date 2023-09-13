rng = Xoshiro(1)
doprecrossover = true
if doprecrossover
    dolongtest = false
    if dolongtest
        @testset "Larger template layout calc" begin
            cc = CalculatorConfig(populationsize=2000, crossoverweight=0, maxiter=100)
            sf = BasicScoreFunction()
            glc = GeneticLayoutCalculator(cc, sf)
            km = gen4x12keymap(1, 4, 12)
            km[KeyLocation(1, (1, 1))] = Key(_TAB, false)
            fh = BasicFrequencyTemplate
            km, s1, s2, s3 = calculatelayout(rng, glc, km, fh)
            println(km)
            println(s1)
            println(s2)
            println(s3)
            println("Min of the mins ", minimum(s2))
            finscore = calculatescore(sf, km, fh)
            println("Final score ", finscore)

            el = gen4x12effortlayer()
            dvorakkeymap = Keymap(Layer([
                Key.([_TAB,     nothing, _COMM, _DOT, _P, _Y, _F, _G, _C, _R, _L, nothing]),
                Key.([nothing,  _A, _O, _E, _U, _I, _D, _H, _T, _N, _S, _ENT]),
                Key.([_SFT,     nothing, _Q, _J, _K, _X, _B, _M, _W, _V, _Z, _SFT]),
                Key.([nothing,  nothing, nothing, nothing, nothing, _SPC, _BSPC, nothing, nothing, nothing, nothing, nothing])
            ]), layerswitches=LayerSwitchmap(KeyLocation()), effortlayer=el)
            dvscore = calculatescore(sf, dvorakkeymap, fh)
            println("A good score ", dvscore)
            
            testmap = Keymap(Layer([
                Key.([_TAB     ,_J     ,_P   ,_SFT   ,_SPC     ,_O     ,_V     ,_Q   ,_SFT     ,_T   ,_DOT      ,_NO]),
                Key.([_W     ,_L     ,_H     ,_I     ,_A     ,_S     ,_B     ,_R     ,_L  ,_COMM     ,_G     ,_F]),
                Key.([_K     ,_F      ,_NO   ,_ENT     ,_Y     ,_C     ,_X     ,_N     ,_U  ,_BSPC      ,_NO  ,_NO]),
                Key.([_Z     ,_Z   ,_DOT      ,_NO    ,_LS     ,_E     ,_D    ,_LS   ,_DOT     ,_M     ,_Q  ,_NO])
            ]), layerswitches=LayerSwitchmap(KeyLocation()), effortlayer=el)
            remscore = calculatescore(sf, testmap, fh)
            println("Score when removing some useless keys ", remscore)
            @test finscore == remscore
        end

    else
        println("Skipping long test for now.")
    end


    dolongtest2 = false
    if dolongtest2
        @testset "Larger template layout calc with layer switch swaps" begin
            cc = CalculatorConfig(populationsize=1000, crossoverweight=0, maxiter=200)
            sf = BasicScoreFunction()
            glc = GeneticLayoutCalculator(cc, sf)
            km = gen4x12keymap(3, 4, 12; layerswitchmoveability=true)
            km[KeyLocation(1, (1, 1))] = Key(_TAB, false)
            fh = BasicFrequencyTemplate
            km, s1, s2, s3 = calculatelayout(rng, glc, km, fh)
            println(km)
            println(s1)
            println(s2)
            println(s3)
            println("Min of the mins ", minimum(s2))
            finscore = calculatescore(sf, km, fh)
            println("Final score ", finscore)

        end
    else
        println("Skipping long test 2 for now.")
    end
else
    println("skipping precrossover tests for now")
end


import AdvancedLayoutCalculator.Calculators: _movelayerswitchesfrom1to2!, getbasekmpermutation, getkmpermutation, crossover!


global_logger(ConsoleLogger(stdout, AboveMaxLevel))
dosinglelayercrossovertset = false
if dosinglelayercrossovertset
    @testset "single layer larger template" begin
        cc = CalculatorConfig(populationsize=1000, maxiter=200)
        sf = BasicScoreFunction()
        glc = GeneticLayoutCalculator(cc, sf)
        km = gen4x12keymap(1, 4, 12)
        km[KeyLocation(1, (1, 1))] = Key(_TAB, false)
        # just to test if moveability works with crossover
        km[KeyLocation(1, (2, 1))] = Key(_E, false)
        fh = BasicFrequencyTemplate
        km, s1, s2, s3 = calculatelayout(rng, glc, km, fh)
        println(km)
        println(s1)
        println(s2)
        println(s3)
        println("Min of the mins ", minimum(s2))
        finscore = calculatescore(sf, km, fh)
        println("Final score ", finscore)
    end
else
    println("skipping single layer large crossover test")
end


global_logger(ConsoleLogger(stdout, currentdebuglevel))
dolongcrossovertest = false
if dolongcrossovertest
    @testset "Larger template layout calc with layer switch swaps" begin
        cc = CalculatorConfig(populationsize=1000, maxiter=200, earlystopping = (x, y) -> return false)
        sf = BasicScoreFunction()
        glc = GeneticLayoutCalculator(cc, sf)
        km = gen4x12keymap(3, 4, 12; layerswitchmoveability=true)
        el = gen4x12effortlayer()
        # layer switch happens from 2->3 instead of 1->3
        km[KeyLocation(1, (4, 8))] = Key()
        km[KeyLocation(2, (4, 8))] = Key(_LS)
        km[KeyLocation(1, (1, 1))] = Key(_TAB, false)
        km[KeyLocation(1, (4, 6))] = Key(_SPC, false)
        km[KeyLocation(1, (4, 7))] = Key(_BSPC, false)
        km[KeyLocation(3, (3, 11))] = Key(_LCTL, false)

        km[KeyLocation(2, (1, 2))] = Key(_1, false)
        km[KeyLocation(2, (1, 3))] = Key(_2, false)
        km[KeyLocation(2, (1, 4))] = Key(_3, false)
        km[KeyLocation(2, (1, 5))] = Key(_4, false)
        km[KeyLocation(2, (1, 6))] = Key(_5, false)

        km[KeyLocation(2, (2, 2))] = Key(_6, false)
        km[KeyLocation(2, (2, 3))] = Key(_7, false)
        km[KeyLocation(2, (2, 4))] = Key(_8, false)
        km[KeyLocation(2, (2, 5))] = Key(_9, false)
        km[KeyLocation(2, (2, 6))] = Key(_0, false)

        km[KeyLocation(1, (3, 1))] = Key(_SFT, true, true)
        km[KeyLocation(1, (3, 12))] = Key(_SFT, true, true)
        km = Keymap(layers(km); layerswitches=LayerSwitchmap(KeyLocation(), KeyLocation(1, 4, 5), KeyLocation(2, 4, 8)), effortlayer=el)

        
        fh = BasicFrequencyTemplate
        km, s1, s2, s3 = calculatelayout(rng, glc, km, fh)
        println(km)
        println(s1)
        println(s2)
        println(s3)
        println("Min of the mins ", minimum(s2))
        finscore = calculatescore(sf, km, fh)
        println("Final score ", finscore)
        
        # with crossover, score of 183.27499999999995 (168.0) after 3m:25s
        # 1000 pop, 200 iter
        # swap count: 50033, layer switch swap count: 2499, identity count: 31046, replace count: 50062, crossover count: 66360

        # no crossovers, score of 234.975 (229.025) after 4m:04s
        # 2000 pop, 400 iter
        # swap count: 300662, layer switch swap count: 15036, identity count: 183634, replace count: 300668, crossover count: 0

        # crossoverweight::Float32 = 1
        # swapmutationweight::Float32 = 1 # counts for mutation vs crossover
        # identityweight::Float32 = 0.5 # only counts for mutation
        # replacepointmutationweight::Float32 = 1 # counts for mutation vs crossover

        @testset "immovable keys don't move" begin
            @test km[KeyLocation(1, (1, 1))] == Key(_TAB, false)
            @test km[KeyLocation(1, (4, 6))] == Key(_SPC, false)
            @test km[KeyLocation(1, (4, 7))] == Key(_BSPC, false)
            @test km[KeyLocation(3, (3, 11))] == Key(_LCTL, false)

            @test km[KeyLocation(2, (1, 2))] == Key(_1, false)
            @test km[KeyLocation(2, (1, 3))] == Key(_2, false)
            @test km[KeyLocation(2, (1, 4))] == Key(_3, false)
            @test km[KeyLocation(2, (1, 5))] == Key(_4, false)
            @test km[KeyLocation(2, (1, 6))] == Key(_5, false)

            @test km[KeyLocation(2, (2, 2))] == Key(_6, false)
            @test km[KeyLocation(2, (2, 3))] == Key(_7, false)
            @test km[KeyLocation(2, (2, 4))] == Key(_8, false)
            @test km[KeyLocation(2, (2, 5))] == Key(_9, false)
            @test km[KeyLocation(2, (2, 6))] == Key(_0, false)

            @test issymmetric(km[keypathmap(km)[_SFT][1][end]])
        end
    end
else
    println("Skipping long crossover test for now.")
end


global_logger(ConsoleLogger(stdout, currentdebuglevel))
prideandprejtext = false
if prideandprejtext
    @testset "Test of Pride and Prej" begin
        cc = CalculatorConfig(populationsize=1000, maxiter=200, earlystopping = (x, y) -> return false)
        sf = BasicScoreFunction()
        glc = GeneticLayoutCalculator(cc, sf)
        km = gen4x12keymap(3, 4, 12; layerswitchmoveability=true)
        km[KeyLocation(1, (1, 1))] = Key(_TAB, false)
        # km[KeyLocation(1, (4, 6))] = Key(_SPC, false)
        # km[KeyLocation(1, (4, 7))] = Key(_BSPC, false)
        km[KeyLocation(3, (3, 11))] = Key(_LCTL, false)

        km[KeyLocation(2, (1, 2))] = Key(_1, false)
        km[KeyLocation(2, (1, 3))] = Key(_2, false)
        km[KeyLocation(2, (1, 4))] = Key(_3, false)
        km[KeyLocation(2, (1, 5))] = Key(_4, false)
        km[KeyLocation(2, (1, 6))] = Key(_5, false)

        km[KeyLocation(2, (2, 2))] = Key(_6, false)
        km[KeyLocation(2, (2, 3))] = Key(_7, false)
        km[KeyLocation(2, (2, 4))] = Key(_8, false)
        km[KeyLocation(2, (2, 5))] = Key(_9, false)
        km[KeyLocation(2, (2, 6))] = Key(_0, false)

        # km[KeyLocation(1, (3, 1))] = Key(_SFT, true, true)
        # km[KeyLocation(1, (3, 12))] = Key(_SFT, true, true)

        el = gen4x12effortlayer()
        fh = SimpleFrequencyHolder("data/1342-0.txt"; shiftedsymbols=Set{Keycode}())
        km, s1, s2, s3 = calculatelayout(rng, glc, km, fh)
        println(km)
        println(s1)
        println(s2)
        # println(s3)
        println("Min of the mins ", minimum(s2))
        finscore = calculatescore(sf, km, fh)
        println("Final score ", finscore)
        
        @testset "immovable keys don't move" begin
            @test km[KeyLocation(1, (1, 1))] == Key(_TAB, false)
            # @test km[KeyLocation(1, (4, 6))] == Key(_SPC, false)
            # @test km[KeyLocation(1, (4, 7))] == Key(_BSPC, false)
            @test km[KeyLocation(3, (3, 11))] == Key(_LCTL, false)

            @test km[KeyLocation(2, (1, 2))] == Key(_1, false)
            @test km[KeyLocation(2, (1, 3))] == Key(_2, false)
            @test km[KeyLocation(2, (1, 4))] == Key(_3, false)
            @test km[KeyLocation(2, (1, 5))] == Key(_4, false)
            @test km[KeyLocation(2, (1, 6))] == Key(_5, false)

            @test km[KeyLocation(2, (2, 2))] == Key(_6, false)
            @test km[KeyLocation(2, (2, 3))] == Key(_7, false)
            @test km[KeyLocation(2, (2, 4))] == Key(_8, false)
            @test km[KeyLocation(2, (2, 5))] == Key(_9, false)
            @test km[KeyLocation(2, (2, 6))] == Key(_0, false)

            @test issymmetric(km[keypathmap(km)[_SFT][1][end]])
        end
    end
else
    println("Skipping pride and prej.")
end


global_logger(ConsoleLogger(stdout, currentdebuglevel))
ohtest = true
if ohtest
    @testset "OH test" begin
        # crossoverweight::Float32 = 1
        # swapmutationweight::Float32 = 0.75
        # identityweight::Float32 = 0.1
        # replacepointmutationweight::Float32 = 0.25
        cc = CalculatorConfig(populationsize=1000, maxiter=50, swapmutationweight=0.5, identityweight=0, replacepointmutationweight=0.25, earlystopping = (x, y) -> return false)
        sf = AdvancedScoreFunction()
        glc = GeneticLayoutCalculator(cc, sf)

        km = gen5x6keymap()
        println(km)
    
        fh = NgramFrequencyHolder("data/1342-0.txt", shiftedsymbols=Commonshiftedsymbols) #, Set{Keycode}([_LBRC, _RBRC, _SLSH])))
        # @test fh[Ngram(_LPRN)] == 35
        km, s1, s2, s3 = calculatelayout(rng, glc, km, fh; symmetricshift=false)
        println(km)
        println(s1)
        println(s2)
        # println(s3)
        println("Min of the mins ", minimum(s2))
        finscore = calculatescore(sf, km, fh)
        println("Final score ", finscore)
        
        @testset "immovable keys don't move" begin
            @test km[KeyLocation(1, (2, 1))] == Key(_TAB, false)
            @test km[KeyLocation(1, (3, 1))] == Key(_LCTL, false)

            # @test issymmetric(km[keypathmap(km)[_LPRN][1][end]])
        end
    end
else
    println("skipping oh test")
end

