@testset "basic score function" begin
    upeffort = 0.19
    lefteffort = 0.2
    downeffort = 0.1
    righteffort = 0.21
    pvecvec = [[Key(_A)], [Key(_E), Key(_O), Key(_U)]]
    pvecvec2 = [[Key(_E)], [Key(_A), Key(_O), Key(_U)]]
    evecvec = [[upeffort], [lefteffort, downeffort, righteffort]]
    ls = LayerSwitchmap(KeyLocation(), KeyLocation(1, (1, 1)))
    el = EffortLayer(evecvec)
    km1 = Keymap(pvecvec, pvecvec2, layerswitches=ls, effortlayer=el)

    bsf = BasicScoreFunction()
    @test 0.19 + 0.2 == scoresequence(bsf, km1, effortlayer(km1), fingermaplayer(km1), KeyLocationSequence(KeyLocation(1, (1, 1)), KeyLocation(2, (2, 1))))
    
    # test a bigram where one keycode has two possible options
    pvecvec = [[Key(_LS), Key(_E)], [Key(_A), Key(_LS), Key(_B)]]
    pvecvec2 = [[Key(_LS), Key(_A)], [Key(_SPC), Key(_TRNS), Key(_N)]]
    evecvec = [[0.15, 0.2], [0.3, 0.4, 0.25]]
    ls = LayerSwitchmap(KeyLocation(), KeyLocation(1, (1, 1)))
    el1 = EffortLayer(evecvec)
    km1 = Keymap(pvecvec, pvecvec2, layerswitches=ls, effortlayer=el1)
    eagram = Ngram([_E, _A])
    fh1 = SimpleFrequencyHolder(Dict{Ngram, Float32}(eagram => 0.5))
    ngramfreqs = getngrams(fh1)
    @test calculatescore(bsf, km1, fh1, ngramfreqs) == 0.25

    angram = Ngram(_A, _N)
    fh2 = SimpleFrequencyHolder(Dict{Ngram, Float32}(angram => 0.75))
    ngramfreqs = getngrams(fh2)
    @test round(calculatescore(bsf, km1, fh2, ngramfreqs), digits=2) == 0.45f0

    fh3 = SimpleFrequencyHolder(Dict{Ngram, Float32}(angram => 0.75, eagram => 0.5))
    ngramfreqs = getngrams(fh3)
    @test round(calculatescore(bsf, km1, fh3, ngramfreqs), digits=2) == 0.7f0

    pvecvec3 = [[Key(_K), Key(_B)], [Key(_I), Key(_LS), Key(_C)]]
    ls2 = LayerSwitchmap(KeyLocation(), KeyLocation(1, (1, 1)), KeyLocation(1, (2, 2)))
    km2 = Keymap(pvecvec, pvecvec2, pvecvec3, layerswitches=ls2, effortlayer=el1)
    eigram = Ngram(_E, _I)
    fh4 = SimpleFrequencyHolder(Dict{Ngram, Float32}(eigram => 0.3))
    ngramfreqs = getngrams(fh4)
    @test round(calculatescore(bsf, km2, fh4, ngramfreqs), digits=2) == 0.27f0
    fh5 = SimpleFrequencyHolder(Dict{Ngram, Float32}(angram => 0.75, eagram => 0.5, eigram => 0.3))
    ngramfreqs = getngrams(fh5)
    @test round(calculatescore(bsf, km2, fh5, ngramfreqs), digits=2) == 0.97f0

    ncgram = Ngram(_N, _C)
    fh6 = SimpleFrequencyHolder(Dict{Ngram, Float32}(ncgram => 0.1))
    ngramfreqs = getngrams(fh6)
    @test round(calculatescore(bsf, km2, fh6, ngramfreqs), digits=3) == 0.105f0
end


import AdvancedLayoutCalculator.ScoreFunctions: checkfingerroll
@testset "helpers" begin
    @test checkfingerroll([pinkie, ring, middle, index, thumb])
    @test checkfingerroll([pinkie, ring, thumb])
    @test !checkfingerroll([pinkie, ring, index, middle, thumb])
    @test !checkfingerroll([ring, index, middle])
    @test checkfingerroll([thumb, index, middle, ring, pinkie])
    @test !checkfingerroll([thumb, index, ring, middle, pinkie])
end

global_logger(ConsoleLogger(stdout, currentdebuglevel))
@testset verbose=true "advanced score function" begin

    advsf = AdvancedScoreFunction(
        description = "",
        holdliftpenalty = 2.0,
        rollbonus = 0.5,
        maxrolllength = 4,
        samefingerpenalty = 3,
        layerswitchcd = 4,
        layerswitchpenalty = 3.5,
        bigrambonus = 0.25,
        multirowpenalty = 1.25,
        multirowmod = 0.5
    )

    el = EffortLayer([[4., 3., 2., 1., 0.5]])
    fl = FingerMapLayer([[(left, pinkie), (left, ring), (left, middle), (left, index), (left, index)]])
    l1 = layer"""
        M   H   T   E   G
    """
    km = Keymap(l1; layerswitches=LayerSwitchmap(), effortlayer=el, fingermaplayer=fl)

    @testset "same finger" begin
        seq = KeyLocationSequence(KL(1, 1, 4), KL(1, 1, 4))
        baseeffort = 2*1.0
        expectedscore = baseeffort + advsf.samefingerpenalty*baseeffort
        @test scoresequence(advsf, km, el, fl, seq) == expectedscore

        seq = KeyLocationSequence(KL(1, 1, 4), KL(1, 1, 4), KL(1, 1, 4)) 
        baseeffort = 3*1.0
        expectedscore = baseeffort + baseeffort*advsf.samefingerpenalty^2
        @test scoresequence(advsf, km, el, fl, seq) == expectedscore

        seq = KeyLocationSequence(KL(1, 1, 4), KL(1, 1, 4), KL(1, 1, 5)) 
        baseeffort = 2*1.0+0.5
        expectedscore = baseeffort + baseeffort*advsf.samefingerpenalty^2 - (1.0 + 0.5)*advsf.bigrambonus
        @test scoresequence(advsf, km, el, fl, seq) == expectedscore
        println(seq)
        println(expectedscore)

        seq = KeyLocationSequence(KL(1, 1, 4), KL(1, 1, 4), KL(1, 1, 5), KL(1, 1, 5)) 
        baseeffort = 2*1.0+2*0.5
        expectedscore = baseeffort + baseeffort*advsf.samefingerpenalty^3 - (1.0 + 0.5)*advsf.bigrambonus
        @test scoresequence(advsf, km, el, fl, seq) == expectedscore
        println(seq)
        println(expectedscore)

        seq = KeyLocationSequence(KL(1, 1, 4), KL(1, 1, 4), KL(1, 1, 5), KL(1, 1, 5), KL(1, 1, 4)) 
        baseeffort = 2*1.0+2*0.5
        expectedscore = baseeffort + baseeffort*advsf.samefingerpenalty^3 + 1 + 1*advsf.samefingerpenalty - 2*(1.0 + 0.5)*advsf.bigrambonus
        @test scoresequence(advsf, km, el, fl, seq) == expectedscore
        println(seq)
        println(expectedscore)
    end

    multirowel = elayer"""
        4.2 3.2 2.2 1.2 0.7
        4.  3.  2.  1.  0.5
        5.1 4.1 3.1 2.1 0.6

    """
    multirowfl = flayer"""
        (left,pinkie) (left,ring) (left,middle) (left,index) (left,index)
        (left,pinkie) (left,ring) (left,middle) (left,index) (left,index)
        (left,pinkie) (left,ring) (left,middle) (left,index) (left,index)
    """
    
    l1 = layer"""
        A   B   C   D   F
        M   H   T   E   G
        J   K   L   N   O
    """
    multirowkm = Keymap(l1; layerswitches=LayerSwitchmap(), effortlayer=multirowel, fingermaplayer=multirowfl)

    @testset "bigram bonus (no multirow)" begin
        seq = KeyLocationSequence(KL(1, 2, 4), KL(1, 2, 5)) 
        baseeffort = 1.0 + 0.5
        expectedscore = baseeffort + advsf.samefingerpenalty*baseeffort - baseeffort * advsf.bigrambonus
        @test scoresequence(advsf, multirowkm, multirowel, multirowfl, seq) == expectedscore
        println(seq)
        println(expectedscore)

        seq = KeyLocationSequence(KL(1, 2, 4), KL(1, 2, 3)) 
        baseeffort = 1.0 + 2.0
        expectedscore = baseeffort - baseeffort*advsf.bigrambonus
        @test scoresequence(advsf, multirowkm, multirowel, multirowfl, seq) == expectedscore
        println(seq)
        println(expectedscore)
    end

    @testset "roll bonus" begin

        seq = KeyLocationSequence(KL(1, 2, 1), KL(1, 2, 3), KL(1, 2, 5)) 
        baseeffort = 4.0 + 2.0 + 0.5
        expectedscore = baseeffort - baseeffort * advsf.rollbonus
        @test scoresequence(advsf, multirowkm, multirowel, multirowfl, seq) == expectedscore
        println(seq)
        println(expectedscore)

        seq = KeyLocationSequence(KL(1, 3, 1), KL(1, 3, 3), KL(1, 2, 5)) 
        baseeffort = 5.1 + 3.1 + 0.5
        expectedscore = baseeffort - baseeffort * advsf.rollbonus
        @test convert(Float32, round(scoresequence(advsf, multirowkm, multirowel, multirowfl, seq), digits=6)) == round(convert(Float32, expectedscore), digits=6)
        println(seq)
        println(expectedscore)

        seq = KeyLocationSequence(KL(1, 3, 1), KL(1, 3, 3), KL(1, 1, 5)) 
        baseeffort = 5.1 + 3.1 + 0.7
        expectedscore = baseeffort - baseeffort * advsf.rollbonus + (3.1 + 0.7)*(1 + (advsf.multirowpenalty-1)*advsf.multirowmod)
        @test convert(Float32, round(scoresequence(advsf, multirowkm, multirowel, multirowfl, seq), digits=6)) == round(convert(Float32, expectedscore), digits=6)
        println(seq)
        println(expectedscore)

        seq = KeyLocationSequence(KL(1, 2, 1), KL(1, 2, 2), KL(1, 2, 3), KL(1, 2, 5)) 
        baseeffort = 4.0 + 3.0 + 2.0 + 0.5
        expectedscore = baseeffort - baseeffort * advsf.rollbonus^2 - (4.0 + 3.0)*advsf.bigrambonus - (3.0 + 2.0)*advsf.bigrambonus
        @test scoresequence(advsf, multirowkm, multirowel, multirowfl, seq) == expectedscore
        println(seq)
        println(expectedscore)

        seq = KeyLocationSequence(KL(1, 3, 1), KL(1, 3, 2), KL(1, 2, 3), KL(1, 1, 4)) 
        baseeffort = 5.1 + 4.1 + 2.0 + 1.2
        expectedscore = baseeffort - baseeffort * advsf.rollbonus^2 - (5.1 + 4.1)*advsf.bigrambonus
        @test round(scoresequence(advsf, multirowkm, multirowel, multirowfl, seq), digits=6) == round(convert(Float32, expectedscore), digits=6)
        println(seq)
        println(expectedscore)

        seq = KeyLocationSequence(KL(1, 1, 4), KL(1, 2, 3), KL(1, 3, 2), KL(1, 3, 1)) 
        @test round(scoresequence(advsf, multirowkm, multirowel, multirowfl, seq), digits=6) == round(convert(Float32, expectedscore), digits=6)
        println(seq)
        println(expectedscore)

        seq = KeyLocationSequence(KL(1, 3, 1), KL(1, 3, 2), KL(1, 1, 3), KL(1, 1, 4)) 
        baseeffort = 5.1 + 4.1 + 2.2 + 1.2
        expectedscore = baseeffort - baseeffort*advsf.rollbonus^2 - (5.1 + 4.1)*advsf.bigrambonus + 
        (4.1 + 2.2)*(1 + (advsf.multirowpenalty-1)*advsf.multirowmod) - 
        (2.2 + 1.2)*advsf.bigrambonus
        @test convert(Float32, round(scoresequence(advsf, multirowkm, multirowel, multirowfl, seq), digits=6)) == round(convert(Float32, expectedscore), digits=6)
        println(seq)
        println(expectedscore)

        seq = KeyLocationSequence(KL(1, 3, 1), KL(1, 2, 2), KL(1, 3, 3), KL(1, 2, 4)) 
        baseeffort = 5.1 + 3 + 3.1 + 1.0
        expectedscore = baseeffort
        @test convert(Float32, round(scoresequence(advsf, multirowkm, multirowel, multirowfl, seq), digits=6)) == round(convert(Float32, expectedscore), digits=6)
        println(seq)
        println(expectedscore)

    end

    @testset "multirow penalty" begin
    
        seq = KeyLocationSequence(KL(1, 1, 3), KL(1, 3, 4)) 
        baseeffort = 2.2 + 2.1
        expectedscore = baseeffort + baseeffort*advsf.multirowpenalty
        @test convert(Float32, round(scoresequence(advsf, multirowkm, multirowel, multirowfl, seq), digits=6)) == round(convert(Float32, expectedscore), digits=6)
        println(seq)
        println(expectedscore)
    
        seq = KeyLocationSequence(KL(1, 1, 1), KL(1, 3, 2), KL(1, 1, 3)) 
        baseeffort = 4.2 + 4.1 + 2.2
        expectedscore = baseeffort + (4.2 + 4.1)*advsf.multirowpenalty + (2.2)*advsf.multirowpenalty
        @test convert(Float32, round(scoresequence(advsf, multirowkm, multirowel, multirowfl, seq), digits=4)) == round(convert(Float32, expectedscore), digits=4)
        println(seq)
        println(expectedscore)

    end

    multirowel = elayer"""
        4.2 3.2 2.2
        4.  3.  2. 
        5.1 4.1 3.1

    """
    multirowfl = flayer"""
        (left,pinkie) (left,ring) (left,middle) 
        (left,pinkie) (left,ring) (left,middle) 
        (left,thumb) (left,thumb) (left,thumb)
    """
    
    l1 = layer"""
        A   B   C
        M   H   T
        J   K   L
    """
    multirowkm = Keymap(l1; layerswitches=LayerSwitchmap(), effortlayer=multirowel, fingermaplayer=multirowfl)

    @testset "multirow with thumb" begin
        seq = KeyLocationSequence(KL(1, 1, 1), KL(1, 3, 3)) 
        baseeffort = 4.2 + 3.1
        expectedscore = baseeffort
        @test round(scoresequence(advsf, multirowkm, multirowel, multirowfl, seq), digits=6) == round(expectedscore, digits=6)
        println(seq)
        println(expectedscore)
    end


    multilayerel = elayer"""
    4.  3.  2.  1.  0.5

    """
    multilayerfl = flayer"""
        (left,pinkie) (left,ring) (left,middle) (left,index) (left,index)
    """

    l1 = layer"""
        M   H   T   E   LS
    """
    l2 = layer"""
        A   B   C   D   LS 
    """
    multilayerkm = Keymap(l1, l2; layerswitches=LayerSwitchmap(KL(), KL(1, 1, 5)), effortlayer=multirowel, fingermaplayer=multirowfl)

    @testset "layer switching" begin

        # same finger layer switch
        seq = KeyLocationSequence(KL(1, 1, 5), KL(2, 1, 4)) 
        baseeffort = 0.5 + 1.0
        expectedscore = baseeffort + baseeffort*advsf.samefingerpenalty - baseeffort*advsf.bigrambonus
        @test round(scoresequence(advsf, multilayerkm, multilayerel, multilayerfl, seq), digits=6) == round(convert(Float32, expectedscore), digits=6)
        println(seq)
        println(expectedscore)

        # simple layer switch
        seq = KeyLocationSequence(KL(1, 1, 1), KL(1, 1, 5), KL(2, 1, 2)) 
        baseeffort = 4.0 + 0.5 + 3.0
        expectedscore = baseeffort
        @test round(scoresequence(advsf, multilayerkm, multilayerel, multilayerfl, seq), digits=6) == round(convert(Float32, expectedscore), digits=6)
        println(seq)
        println(expectedscore)

        # layer switch + lifting layer hold
        seq = KeyLocationSequence(KL(1, 1, 1), KL(1, 1, 5), KL(2, 1, 2), KL(1, 1, 3)) 
        baseeffort = 4.0 + 0.5 + 3.0 + 2.0
        expectedscore = baseeffort - (3.0 + 2.0)*advsf.bigrambonus + 0.5*advsf.holdliftpenalty
        @test round(scoresequence(advsf, multilayerkm, multilayerel, multilayerfl, seq), digits=6) == round(convert(Float32, expectedscore), digits=6)
        println(seq)
        println(expectedscore)

        # staying in layer
        seq = KeyLocationSequence(KL(1, 1, 1), KL(1, 1, 5), KL(2, 1, 2), KL(2, 1, 4)) 
        baseeffort = 4.0 + 0.5 + 3.0 + 1.0
        expectedscore = baseeffort
        @test round(scoresequence(advsf, multilayerkm, multilayerel, multilayerfl, seq), digits=6) == round(convert(Float32, expectedscore), digits=6)
        println(seq)
        println(expectedscore)

        # layer switch cooldown
        seq = KeyLocationSequence(KL(1, 1, 5), KL(2, 1, 1), KL(1, 1, 3), KL(1, 1, 5), KL(2, 1, 3)) 
        baseeffort = 0.5 + 4.0 + 2.0 + 0.5 + 2.0
        expectedscore = baseeffort + 0.5*advsf.layerswitchpenalty - (4.0 + 2.0 + 0.5)*advsf.rollbonus + 0.5*advsf.holdliftpenalty
        @test round(scoresequence(advsf, multilayerkm, multilayerel, multilayerfl, seq), digits=6) == round(convert(Float32, expectedscore), digits=6)
        println(seq)
        println(expectedscore) 
    end


    # multilayerel = elayer"""
    # 4.  3.  2.  1.  0.5

    # """
    # multilayerfl = flayer"""
    #     (left,pinkie) (left,ring) (left,middle) (left,index) (left,index)
    # """

    # l1 = layer"""
    #     M   H   T   E   LS
    # """
    # l2 = layer"""
    #     A   B   C   D   LS 
    # """

    @testset "cancels" begin
        seq = KeyLocationSequence(KL(1, 1, 5), KL(2, 1, 3), KL(1, 1, 5), KL(2, 1, 3), KL(1, 1, 5), KL(2, 1, 2), KL(1, 1, 5), KL(2, 1, 1))
        baseeffort = 0.5 + 2.0 + 2.0 + 3.0 + 4.0
        expectedscore = baseeffort + (2.0+2.0)*advsf.samefingerpenalty - (2.0 + 3.0)*advsf.bigrambonus - (3.0 + 4.0)*advsf.bigrambonus - (2.0 + 3.0 + 4.0)*advsf.rollbonus
        @test round(scoresequence(advsf, multilayerkm, multilayerel, multilayerfl, seq), digits=6) == round(convert(Float32, expectedscore), digits=6)
        println(seq)
        println(expectedscore)

        seq = KeyLocationSequence(KL(1, 1, 5), KL(2, 1, 3), KL(1, 1, 5), KL(2, 1, 4))
        baseeffort = 0.5 + 2.0 + 0.5 + 1.0
        expectedscore = baseeffort + (0.5 + 1.0)*advsf.samefingerpenalty - (0.5 + 1.0)*advsf.bigrambonus + 0.5*advsf.layerswitchpenalty - 0.5 # layer switch held
        @test round(scoresequence(advsf, multilayerkm, multilayerel, multilayerfl, seq), digits=6) == round(convert(Float32, expectedscore), digits=6)
        println(seq)
        println(expectedscore)
    end

end


