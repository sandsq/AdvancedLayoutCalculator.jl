@testset "Key" begin
    k = Key(0.1f0)
    @test value(k) == 0.1f0
    @test contenttype(k) == Float32
    @test ismoveable(k)

    k1 = Key(1, false)
    k2 = Key(1, false)
    @test k1 == k2

    kn = Key()
    @test value(kn) === nothing
    @test ismoveable(kn)
end

@testset verbose=true "Layer-related tests" begin


    @testset "Indexing grid" begin
        @test grid2index(3, 5, (2, 3)) == 8
        @test grid2index(3, 5, (1, 1)) == 1
        @test grid2index(3, 5, (3, 5)) == 15
        @test index2grid(3, 5, 1) == (1, 1)
        @test index2grid(3, 5, 7) == (2, 2)
        @test index2grid(3, 5, 6) == (2, 1)
        @test index2grid(3, 5, 12) == (3, 2)
        @test index2grid(3, 5, 15) == (3, 5)
    end

    @testset "ProtoLayer" begin
        pvecvec = [[1, 1], [4, 5, 6], [8, 10, 11]]
        p = ProtoLayer(pvecvec)
        @test layout(p) == pvecvec
        @test numrows(p) == 3
        @test dimensions(p) == (3, 3)
        @test dimensionsgran(p) == [2, 3, 3]
        @test eltype(p) == Int
        @test p[2, 3] == 6
        setlayerindex!(p, 50, 2, 3)
        @test p[2, 3] == 50
        p[KeyLocation(1, (2, 3))] = 100
        @test numelements(p) == 8
        
        kl = KeyLocation(1, (2, 2))
        @test p[kl] == 5

        p2 = ProtoLayer([[1, 1], [4, 5, 100], [8, 10, 11]])
        @test p == p2        
    end

    @testset "Layer" begin
        pvecvec = [[Key(_A)], [Key(_E), Key(_O), Key(_U)]]
        l = Layer(ProtoLayer(pvecvec))
        l2 = Layer(pvecvec)
        @test l == l2

        l3 = gentemplatelayer(4, 12)
        @test numrows(l3) == 4
        @test dimensions(l3) == (4, 12)

        l4 = Layer([[Key(), Key(), Key(), Key(), Key()], [Key(), Key(), Key(), Key(), Key()], [Key(), Key(), Key(), Key(), Key()]])
        @test grid2index(l4, (2, 3)) == 8
        @test index2grid(l4, 8) == (2, 3)


        pvecvec = [[Key(_A), Key(), Key(_SFT)], [Key(_E), Key(_O), Key(_U)]]
        l = Layer(ProtoLayer(pvecvec))
        litlayer = layer"""
            A __ SFT
            E O U
        """
        @test l == litlayer

    end

    @testset "Create Layer with mismatched key types" begin
        pvecvec = [[Key(_A)], [Key(_E), Key(), Key(0.97f0)]]
        l = Layer(ProtoLayer(pvecvec))
        l2 = Layer(pvecvec)
        @test l == l2
    end

end

@testset "Randomized layers" begin
    rng = Xoshiro(1)
    template = [[Key()], [Key(), Key(_E, false), Key()]]
    
    randlayer, remainingkeys = genrandomlayer(rng, template, [_A, _E, _O, _U, _SPC])
    @test layout(randlayer) == [[Key(_SPC)], [Key(_E), Key(_E, false), Key(_A)]]
    @test remainingkeys == [_U, _O]

    template2 = [[Key()], [Key(), Key(_E, false), Key()]]
    randlayer2, remkeys2 = genrandomlayer(rng, template2, [_A]) # revise test to not depend on random state?
    @test randlayer2 == Layer([[Key(_A)], [Key(_A), Key(_E, false), Key(_A)]])
    @test length(remkeys2) == 0
    randlayer3, remkeys3 = genrandomlayer(rng, template2, [_A, _SFT]) # revise test to not depend on random state?
    @test randlayer3 == Layer([[Key(_A)], [Key(_SFT, true, true), Key(_E, false), Key(_SFT, true, true)]])

    template4 = Layer([[Key(_O), Key()], [Key(), Key(_E, false), Key()]])
    randlayer4, remkeys4 = genrandomlayer(rng, template4, [_A, _SFT])
    @test randlayer4 == Layer([[Key(_SFT, true, true), Key(_SFT, true, true)], [Key(_O), Key(_E, false), Key(_A)]])
end
# include("benchmark_layers.jl")

@testset "Layer switchmap" begin
    pvecvec = [[Key(_A)], [Key(_E), Key(_O), Key(_A)]]
    pvecvec2 = [[Key(_A)], [Key(_E), Key(_LSFT), Key(_O)]]
    pvecvec3 = [[Key()], [Key(), Key(), Key(_SPC)]]
    pvecvec4 = [[Key()], [Key(_LCTL), Key(), Key()]]

    ls = [KeyLocation(), KeyLocation(1, (2, 3)), KeyLocation(2, (1, 1)), KeyLocation(1, (2, 1))]
    ls = LayerSwitchmap(ls)

    @test switchmap(ls)[3] == KeyLocationSequence(KeyLocation(1, (2, 3)), KeyLocation(2, (1, 1)))
    @test switchmap(ls)[4] == KeyLocationSequence(KeyLocation(1, (2, 1)))
    
    @test findsequencetolocation(ls, KeyLocation(3, (2, 3))) == KeyLocationSequence(KeyLocation(1, (2, 3)), KeyLocation(2, (1, 1)), KeyLocation(3, (2, 3)))
    @test findsequencetolocation(ls, KeyLocation(4, (2, 1))) == KeyLocationSequence(KeyLocation(1, (2, 1)), KeyLocation(4, (2, 1)))

end

@testset verbose=true "Keymap" begin
    pvecvec = [[Key(_A)], [Key(_E), Key(_O), Key(_LCTL)]]
    pvecvec2 = [[Key(_A)], [Key(_E), Key(_O), Key(_LCTL)]]
    pvecvec3 = [[Key(_SPC), Key(_LSFT)]]

    ls = [KeyLocation(), KeyLocation(1, (2, 1))]
    ls = LayerSwitchmap(ls)

    km1 = Keymap(Layer(pvecvec), Layer(pvecvec2), layerswitches=ls)
    @testset "Basic keymap methods" begin
        @test baselayer(km1) == Layer(pvecvec)
        @test numelements(km1) == 8
    end

    kl = KeyLocation(2, (2, 3))
    klm = keypathmap(km1)
    @testset "Location indexing and sequence retrieval" begin
        @test km1[kl] == Key(_LCTL)
        @test klm[_LCTL] == [KeyLocationSequence(1, (2, 3)), KeyLocationSequence(KeyLocation(1, (2, 1)), kl)]
        @test getsymmetriclocation(kl, km1) == KeyLocation(2, (2, 1))
    end

    @testset "Empty template keymap" begin
        templatekm = gen4x12keymap()
        @test numlayers(templatekm) == 3
        @test dimensions(baselayer(templatekm)) == (4, 12)
    end

    km2 = Keymap(Layer(pvecvec), Layer(pvecvec2), layerswitches=ls)
    @test km1 == km2

    km2[1, 1, 1] = Key(_SPC)
    km2[KeyLocation(2, (2, 2))] = Key(_TRNS)
    km2[2, 2, 3] = Key(_TRNS)
    @testset "Keymap setindex! correctly updates internals" begin
        @test km2[1, 1, 1] == Key(_SPC)
        @test km2[2, 2, 2] == Key(_TRNS)
        @test km2[2, 2, 3] == Key(_TRNS)
        @test km2 == Keymap(Layer([[Key(_SPC)], [Key(_E), Key(_O), Key(_LCTL)]]), Layer([[Key(_A)], [Key(_E), Key(_TRNS), Key(_TRNS)]]), layerswitches=ls)
        @test km2[_TRNS] == [KeyLocationSequence(KeyLocation(1, (2, 1)), KeyLocation(2, (2, 2))), KeyLocationSequence(KeyLocation(1, (2, 1)), KeyLocation(2, (2, 3)))]
    end

    @test_throws "Every layer in a keymap must have the same shape." km1 = Keymap(Layer(pvecvec), Layer(pvecvec2), Layer(pvecvec3), layerswitches=ls)

    km3 = Keymap(Layer(pvecvec), Layer(pvecvec2), layerswitches=ls)
    swapkeys!(km3, KeyLocation(1, (1, 1)), KeyLocation(2, (2, 2)))
    @test km3[KeyLocation(1, (1, 1))] == Key(_O)
    @test km3[KeyLocation(2, (2, 2))] == Key(_A)
    # replacekey!(km3, Key(), KeyLocation(2, (2, 3)))
    # @test km3[KeyLocation(2, (2, 3))] == Key()


    @testset "Keymap grid indexing" begin
        # km = gen4x12keymap(3, [5, 5, 5])
        l1 = layer"""
            __ __ __ __ __
            __ __ __ __ __
            __ __ __ __ __
        """
        km = Keymap([l1, l1, l1], layerswitches=LayerSwitchmap(KL(), KL(1, 1, 1), KL(1, 1, 2)))
        @test grid2index(km, 2, (2, 2)) == 22
        @test grid2index(km, 3, (3, 4)) == 44
        @test grid2index(km, 1, (1, 1)) == 1
        @test grid2index(km, 3, (3, 5)) == 45
        @test index2grid(km, 22) == KeyLocation(2, (2, 2))
        @test index2grid(km, 44) == KeyLocation(3, (3, 4))
        @test index2grid(km, 1) == KeyLocation(1, (1, 1))
        @test index2grid(km, 45) == KeyLocation(3, (3, 5))
    end

end





@testset "Randomized keymap" begin
    rng = Xoshiro(1)
    pvecvec = [[Key()], [Key(), Key(_E, false), Key(_A, false)]]
    pvecvec2 = [[Key(_A, false)], [Key(), Key(), Key()]]
    ls = LayerSwitchmap(KeyLocation(), KeyLocation(1, (1, 1)))

    template = Keymap(Layer(pvecvec), Layer(pvecvec2), layerswitches=ls)

    randkeymap, remkeys = genrandomkeymap(rng, template, [_A, _E, _O, _U, _SPC, _LSFT, _LCTL]) # revise test to not depend on random state?
    @test randkeymap == Keymap(Layer([[Key(_LCTL)], [Key(_U), Key(_E, false), Key(_A, false)]]), Layer([[Key(_A, false)], [Key(_O), Key(_SPC), Key(_LSFT)]]), layerswitches=ls)
    @test remkeys == []
    @test randkeymap[_A] == [KeyLocationSequence(KeyLocation(1, (2, 3))), KeyLocationSequence(KeyLocation(1, (1, 1)), KeyLocation(2, (1, 1)))]
    
end
