@testset "ngram" begin
    @test ngram"_H_E_L_L_O" == Ngram(_H, _E, _L, _L, _O)
end

@testset "Simple frequency holder" begin

    # grep -Fo ' ' test/data/1342-0.txt | wc -l
    docpath = "data/1342-0.txt"
    fh = SimpleFrequencyHolder(docpath)
    @test fh[Ngram(_E)] == 70510 + 849
    @test fh[Ngram(_SPC)] == 183055
    # @test fh[Ngram(_T, _H)] == 13396 + 695
    println(length(fh))

end


import AdvancedLayoutCalculator.TextProcessor: _getsubngrams
@testset "Ngram frequency holder" begin

    s1 = "inMi\n"
    @testset "string to keycode" begin

        @test char2keycodes('~'; shiftedsymbols=Commonshiftedsymbols) == [_SFT, _GRV]
        @test char2keycodes('~'; shiftedsymbols=Set{Keycode}()) == [_TILD]
        @test string2keycodes(s1; shiftedsymbols=Set{Keycode}()) == [_I, _N, _SFT, _M, _I, _ENT]
    end

    @testset "ngram gen" begin
        grams = _getsubngrams("hello")
        println(grams)
        @test Ngram(_H, _E, _L, _L, _O) in grams
        @test Ngram(_H, _E, _L, _L) in grams
        @test Ngram(_E, _L, _L, _O) in grams

        grams2 = _getsubngrams("Hello")
        println(grams2)
        @test Ngram(_SFT, _H, _E, _L, _L) in grams2
        @test Ngram(_H, _E, _L, _L, _O) in grams2 

        grams3 = _getsubngrams("inMe\n")
        # In this specific case, there are no duplicate letters. So we want to make sure the process isn't duplicating anything.
        @test length(Set(grams3)) == length(grams3)
        println(grams3)

        grams4 = _getsubngrams("app!e"; shiftedsymbols=Set{Keycode}())
        @test Ngram(_A, _P, _P, _EXLM, _E) in grams4
        
        grams5 = _getsubngrams("app!e")
        @test Ngram(_A, _P, _P, _SFT, _1) in grams5
        @test Ngram(_P, _P, _SFT, _1, _E) in grams5
        
    end



    @testset "small file" begin

        ngramconfig = Ngramconfig(
            maxgrams = 5,
            scaletype = :x,
        )

        docpath = "data/smallstring.txt"
        nfh = NgramFrequencyHolder(docpath; config=ngramconfig)
        @test nfh[Ngram(_H, _A)] == 3.0
        # println(nfh)
        ngramconfig = Ngramconfig(
            maxgrams = 5,
            scaletype = :ngramlength,
        )
        nfh = NgramFrequencyHolder(docpath; config=ngramconfig)
        # println(nfh)

        @test round(nfh[Ngram(_H)], digits=6) == convert(Float32, round(4 / 81, digits=6))
        # remember, backspace is artificially added to be the average of E and SPC
    end

    @testset "pride and prej" begin

        ngramconfig = Ngramconfig(
            description = "",
            shiftedsymbols = Set{Keycode}(),
            maxgrams = 5,
            scaletype = :x,
            topns = [-1, 100, 100, 50, 50]
        )

        docpath = "data/1342-0.txt"
        nfh = NgramFrequencyHolder(docpath; config=ngramconfig)
        @test !(_EXLM in keys(nfh[1]))
        @test nfh[Ngram(_SPC)] == 183055
        @test nfh[Ngram(_E)] == 70510 + 849
        @test nfh[Ngram(_P)] == 8439 + 294
        @test nfh[Ngram(_SPC, _SFT)] == 11637
        @test nfh[Ngram(_T, _H, _E)] == 7464 + 534
        @test nfh[Ngram(_DOT, _SPC)] == 4247
        @test nfh[Ngram(_SFT)] == 14221 # assumes shifts only come from capital letters. grep -oP '[A-Z]' test/data/1342-0.txt | wc -l
        # 3grams with space are not considered
        # @test nfh[Ngram(_DOT, _SPC, _SFT)] == 4075 # grep -oP '\. [A-Z]+' test/data/1342-0.txt | wc -l 

        println(nfh[1])
        println(nfh[2])
        println(nfh[3])
        println(nfh[4])
        println(nfh[5])
        @test length(nfh[2]) == 100
        @test length(nfh[5]) == 50
        

        # # nfh2 = NgramFrequencyHolder(docpath; maxgrams=6)
        # docpath2 = "data/2701-0.txt"
        # nfh2 = NgramFrequencyHolder(docpath2; useshiftedsymbols=true)
        # @test nfh2[Ngram(_E)] == 118538 + 827
        # @test nfh2[Ngram(_SFT, _E)] == 827
    end

    import AdvancedLayoutCalculator.TextProcessor: Isstring
    @testset "merging" begin
        ngramconfig = Ngramconfig(
            maxgrams = 5,
            scaletype = :x,
        )

        fh1 = NgramFrequencyHolder("Hi friend", Isstring(); config=ngramconfig) 
        fh2 = NgramFrequencyHolder("Hello hill", Isstring(); config=ngramconfig)
        mergefh!(fh1, fh2, 0.25f0, 0.75f0)
        @test fh1[ngram"_SFT_H"] == 0.25f0 * 1 + 0.75*1
        @test fh1[ngram"_H"] == 0.25f0 * 1 + 0.75 * 2
        @test fh1[ngram"_H_I"] == 0.25f0 * 1 + 0.75 * 1

        ngramconfig = Ngramconfig(
            maxgrams = 5,
            scaletype = :ngramlength,
        )
        fh1 = NgramFrequencyHolder("hatat e", Isstring(); config=ngramconfig) 
        fh2 = NgramFrequencyHolder("thatat ex", Isstring(); config=ngramconfig) 
        println(fh1)
        println(fh2)
        mergefh!(fh1, fh2, 0.25f0, 0.75f0)
        @test round(fh1[ngram"_H_A_T"], digits=6) == round(convert(Float32, 0.25*1/3 + 0.75*1/4), digits=6)
        @test round(fh1[ngram"_T"], digits=6) == round(convert(Float32, 0.25*2/8 + 0.75*3/10), digits=6) # BSPC is set as average of space and E
        @test round(fh1[ngram"_A_T"], digits=6) == round(convert(Float32, 0.25*2/6 + 0.75*2/8), digits=6)


        # fh1 = NgramFrequencyHolder(" hatate", Isstring(); doscaleperlength=false)
        # fh2 = NgramFrequencyHolder("thatatex ", Isstring(); doscaleperlength=false)
        # println(fh1)
        # println(fh2)
    end

end