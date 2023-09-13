using BenchmarkTools
using AdvancedLayoutCalculator
using AdvancedLayoutCalculator.AlcUtils

b = rand(Bool, 10);

# @benchmark length(unique($b)) <= 2
# @benchmark distinctele($b) <= 2
# println(length(unique(b)) == distinctele(b))

@benchmark sum($b[1:100])
@benchmark sum((@view $b[1:100]))

function distinctele(b::Vector{Bool})
    numele = 0
    for e in b
        if !found0 && !e
            numele += 1
            found0 = true
        end
        if !found1 && !e
            numele += 1
            found1 = true
        end
        if numele == 2 return numele end
    end
    return numele
end

begin 
    b = rand(Int, 1000);
    function nunique(a)
        last = first(a)
        n = 1
        for x in a
            if isless(last, x)
                n += 1
                last = x
            end
        end
        n
    end

    # @benchmark length(unique($b)) <= 2
    @benchmark nunique(sort!($b)) <= 2
    # @benchmark maximum($b) - minimum($b)
    # println(length(unique(b)) == nunique(sort!(b)))

    # @benchmark map(x -> x + 1, $b)
    # @benchmark (x -> x + 1).($b)
end

testa = [329, 3, 10, 4]
if length(sort!(testa)) == 4 && testa[end] - testa[1] == 326 println("gotem") end
testa


begin
    import AdvancedLayoutCalculator.ScoreFunctions: checkfingerroll
    io = IOContext(stdout)
    handfings = [(left, pinkie), (left, ring), (left, middle), (left, thumb), (left, index)]
    bench1 = @benchmark checkfingerroll(map(x -> x[2], $handfings))
    bench2 = @benchmark checkfingerroll((x -> x[2]).($handfings))
    show(io, MIME("text/plain"), bench1)
    show(io, MIME("text/plain"), bench2)
end


begin
    vis = rand(Bool, 1000)
    rep = rand(Bool, 100)
    # @benchmark (@view $vis[1:100]) .= rep
    @benchmark $vis[1:100] .= rep
end


begin
    using AdvancedLayoutCalculator.Keyboard
    el = gen4x12effortlayer()
    kls = KeyLocationSequence(KeyLocation(1, 1, 1), KeyLocation(1, 2, 1), KeyLocation(1, 2, 1), KeyLocation(1, 4, 1), KeyLocation(1, 4, 2))
    seq = (@view kls[1:end])
    println(sum(x -> el[x], seq) == sum(map(x -> el[x], seq)))
    @benchmark sum(x -> $el[x], $seq)

    
    
    # elvec = [[rand(12)]; [rand(12)]; [rand(12)]; [rand(12)]];
    # @benchmark $el[KeyLocation(1, 2, 2)]
    # @benchmark $elvec[2][2]

end



begin
    import AdvancedLayoutCalculator.Calculators: _rouletteselection, selectsolutionindexes, RouletteSelector
    using Random
    # probarr = [0.1, 0.3, 0.4, 0.2]
    # reversed = sum(probarr) .- probarr
    # i1, i2 = _rouletteselection(reversed, 1.0, 2.9)
    # println(i1, " ", i2)
    # selectsolutionindex(rng::AbstractRNG, ars::RouletteSelector, scores::Vector{T}; selectionamount=:two) where {T <: Real}
    
    rng = Xoshiro(1)
    probarr = [0.1, 0.3, 0.4, 0.2]
    reversed = sum(probarr) .- probarr
    println(reversed)
    println(reversed ./ sum(reversed))
    inds = [0, 0, 0, 0]
    inds2 = [0, 0, 0, 0]
    
    for i in 1:2500
    
        solninds = selectsolutionindexes(rng, RouletteSelector(), probarr, 1, 1)
        for (i1, i2) in solninds
            inds[i1] += 1
            inds2[i2] += 1
        end
        # r1 = rand(rng)*3
        # r2 = rand(rng)*3
        # # println(r1, " ", r2)
        
        # re1, re2 = min(r1, r2), max(r1, r2)
        # println(r1, " ", r2, " ", re1, " ", re2)
        # r1 = re1
        # r2 = re2
        # i1 = _rouletteselection(sum(probarr) .- probarr, r1, r1)
        
        # # println(i1, " ", i2)
        # inds[i1] += 1
        # i2 = _rouletteselection(sum(probarr) .- probarr, r2, r2)
        # inds2[i2] += 1

        

            
    end
    println(inds)
    println(inds2)

end