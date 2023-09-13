if Threads.nthreads() > 1 error("Run this with one thread") end

using AdvancedLayoutCalculator
using AdvancedLayoutCalculator.Keyboard
using AdvancedLayoutCalculator.AlcUtils
using AdvancedLayoutCalculator.TextProcessor
using BenchmarkTools
using Logging
using Random
using AbstractAlgebra
import AdvancedLayoutCalculator.Calculators: _movelayerswitchesfrom1to2!, _movesymmetrics1to2!, getbasekmpermutation, getkmpermutation, _applykmpermutation!, crossover!, mutate!, swapmutation!, replacementpointmutation!, _calculateinitialsolutions!, _removeunusedkeys!
import AdvancedLayoutCalculator.ScoreFunctions: checkfingerroll, _addtobranch
using JLD2
using UUIDs
using Profile
# using ProfileView
# using PProf
using StatProfilerHTML

numsamples=10
# io = IOContext(stdout)



cc = CalculatorConfig(populationsize=100, maxiter=2, swapmutationweight=0.1, identityweight=0.0, replacepointmutationweight=0.1, earlystopping = (x, y) -> return false)
sf = AdvancedScoreFunction()
glc = GeneticLayoutCalculator(cc, sf)
km = gen5x6keymap(;numlayers=3)

fhpath = "test/Calculator/prideandprej.jld2"
fh = if isfile(fhpath)
        load_object(fhpath)
    else
        NgramFrequencyHolder("./test/data/1342-0.txt", shiftedsymbols=Commonshiftedsymbols)
    end
if !isfile(fhpath) jldsave(fhpath; fh) end

rng = Xoshiro(1)

@info "template\n$km"

km1, _ = genrandomkeymap(rng, km, getuniquekeycodes(fh))
el1 = effortlayer(km1)
fl1 = fingermaplayer(km1)
dummyseq = KeyLocationSequence(KeyLocation(1, 1, 1), KeyLocation(1, 3, 4))#, KeyLocation(1, 3, 5), KeyLocation(1, 2, 2), KeyLocation(2, 3, 6))
km2, _ = genrandomkeymap(rng, km, getuniquekeycodes(fh))
# t = @benchmark crossover!($rng, $km1, $km2) samples=numsamples
# show(io, MIME("text/plain"), t)

# _addtobranch(sf, KeyLocationSequence[dummyseq], KeyLocationSequence[dummyseq])
# @code_warntype _addtobranch(sf, KeyLocationSequence[dummyseq], KeyLocationSequence[dummyseq])
# mutate!(rng, glc, km1, getuniquekeycodes(fh))
# @code_warntype mutate!(rng, glc, km1, getuniquekeycodes(fh))
# crossover!(rng, km1, km2)
# @code_warntype crossover!(rng, km1, km2)

# solns = Vector{Keymap}(undef, cc.populationsize)
# scores = Vector{Float32}(undef, cc.populationsize)
# @code_warntype _calculateinitialsolutions!(rng, sf, km1, fh, cc.populationsize, solns, scores; symmetricshift=false)

# _removeunusedkeys!(sf, km1, fh)
# @code_warntype _removeunusedkeys!(sf, km1, fh)

# scoresequence(sf, km1, effortlayer(km1), fingermaplayer(km1), KeyLocationSequence(KeyLocation(1, 1, 1), KeyLocation(1, 3, 4)))
# calculatescore(sf, km1, fh)
# Profile.clear_malloc_data()
# Profile.Allocs.clear()
# Profile.Allocs.@profile calculatescore(sf, km1, fh)
# PProf.Allocs.pprof()
# exit()
# @code_warntype scoresequence(sf, km1, el1, fl1, dummyseq)
# @code_warntype calculatescore(sf, km1, fh)
# calculatelayout(rng, glc, km, fh; symmetricshift=false, checkpointdir=nothing)
# @code_warntype calculatelayout(rng, glc, km, fh; symmetricshift=false, checkpointdir=nothing)

function calcscorewrapper(sf, km1, fh)
    scores = Float32[]
    ngramfreqs = getngrams(fh)
    for i in 1:100
        s = calculatescore(sf, km1, fh, ngramfreqs)
        push!(scores, s)
    end
    return scores
end

function scoreseqwrapper(sf, km1, el1, fl1, dummyseq)
    scores = Float32[]
    for i in 1:100
        s = scoresequence(sf, km1, el1, fl1, dummyseq)
    end
    push!(scores)
end

runid = string(uuid1())[1:8]
io = open("test/Calculator/timings/$runid.txt", "w")

skipbenchind = true
if !skipbenchind
    benchswap = @benchmark swapmutation!($rng, $glc, $km1) samples=numsamples
    benchreplace = @benchmark replacementpointmutation!($rng, $glc, $km1, getuniquekeycodes($fh)) samples=numsamples
    println(io, "@@@@ swap")
    show(io, MIME("text/plain"), benchswap)
    println(io, "\n@@@@ replace")
    show(io, MIME("text/plain"), benchreplace)


    benchls = @benchmark _movelayerswitchesfrom1to2!($km1, $km2)  samples=numsamples
    _, proceed = _movelayerswitchesfrom1to2!(km1, km2) 
    if !proceed
        opcounts.identitycount += 1
        return km1
    end
    if km1 == km2
        opcounts.identitycount += 1
        return km1
    end
    benchsymm = @benchmark _movesymmetrics1to2!($km1, $km2) samples=numsamples
    _movesymmetrics1to2!(km1, km2)

    benchbase = @benchmark getbasekmpermutation($km1, $km2) samples=numsamples
    basemap = getbasekmpermutation(km1, km2)

    benchperm = @benchmark getkmpermutation($km1, $basemap) samples=numsamples
    σ, layerswitchperms = getkmpermutation(km1, basemap)

    τ, _ = getkmpermutation(km2, basemap)

    permsize = length(σ.d)

    g = SymmetricGroup(permsize)

    ν = σ * inv(τ)
    νcycles = cycles(ν)

    newparr = Vector{Vector{Int}}()
    push!(newparr, cycles(σ)...)
    for c in νcycles
        if length(c) == 1 || length(c) == 2 continue end
        shiftamount = 1:(length(c)-1)
        ĉ = circshift(c, rand(rng, shiftamount))
        ĉ = ĉ[1:Int(ceil(length(ĉ)/2))]
        push!(newparr, ĉ)
    end
    str1 = map(x -> "($(join(x, ", ")))", newparr)
    newandshifted = reduce(*, g.(str1))

    benchapply = @benchmark _applykmpermutation!($rng, $km1, $basemap, $newandshifted) samples=numsamples
    _applykmpermutation!(rng, km1, basemap, newandshifted)

    println(io, "@@@@ initial layer swaps")
    show(io, MIME("text/plain"), benchls)
    println(io, "\n@@@@ initial symm swaps")
    show(io, MIME("text/plain"), benchsymm)
    println(io, "\n@@@@ basemap")
    show(io, MIME("text/plain"), benchbase)
    println(io, "\n@@@@ getting perm")
    show(io, MIME("text/plain"), benchperm)
    println(io, "\n@@@@@ applying perm")
    show(io, MIME("text/plain"), benchapply)
else
    println("skipping benchmarking of individual functions")
end

skipbenchfunc = false
if !skipbenchfunc

    scoresseq = scoreseqwrapper(sf, km1, el1, fl1, dummyseq)
    benchseq = @benchmark scoreseqwrapper($sf, $km1, $el1, $fl1, $dummyseq) samples=1000

    println(io, "\n@@@@ calc seq")
    show(io, MIME("text/plain"), benchseq)

    # _addtobranch(sf, KeyLocationSequence[dummyseq], KeyLocationSequence[dummyseq])
    # benchaddbranch = @benchmark _addtobranch($sf, KeyLocationSequence[$dummyseq], KeyLocationSequence[$dummyseq])

    # println(io, "\n@@@@ add to branch")
    # show(io, MIME("text/plain"), benchaddbranch)

    scores = calcscorewrapper(sf, km1, fh)
    benchscore = @benchmark calcscorewrapper($sf, $km1, $fh) samples=100
        
    println(io, "\n@@@@ calculatescore")
    show(io, MIME("text/plain"), benchscore)
    println(io)
    println(io, "score: ", scores[end])
    
    benchlayout = @benchmark calculatelayout($rng, $glc, $km, $fh; symmetricshift=false, checkpointdir=nothing) samples=10
    println(io, "\n@@@@ calc layout")
    show(io, MIME("text/plain"), benchlayout)
    
else
    println("skipping calcscore and calclayout")
end




# f = Finger[pinkie, ring, middle, index]
# checkfingerroll(f)
# benchfing = @benchmark checkfingerroll($f)
# println(io, "\n@@@@ roll")
# show(io, MIME("text/plain"), benchfing)

# @profilehtml calculatescore(sf, km1, fh)
# @profview calculatescore(sf, km1, fh)
# Profile.print()
# @profile calculatelayout(rng, glc, km, fh; symmetricshift=false, checkpointdir=nothing) 
# Profile.print()


close(io)