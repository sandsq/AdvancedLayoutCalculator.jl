abstract type AbstractSolutionSelector end
struct RouletteSelector <: AbstractSolutionSelector end

"""
    BestScoresSelector
xs: iteration bins to apply given y
ys: e.g., y = 0.5 means we consider an additional 50% of solutions for mutation/crossover. (The base number of solutions we consider is `n` such that `n choose 2` ≈ population size. That way, we are able to construct distinct pairs for crossovers.)
"""
@kwdef struct BestScoresSelector <: AbstractSolutionSelector 
    xs::Vector{Float32} = collect(0:0.2:1)
    ys::Vector{Float32} = [1., 0.25, 0.5, 0.0, 0.0, 0.0]
    function BestScoresSelector(xs, ys)
        if length(xs) != length(ys) error("Incompatible solution cutoff vs iteration progress vector lengths.") end
        return new(xs, ys)
            
    end
end

@kwdef mutable struct CalculatorConfig{F <: Function}
    rundescription::String = ""
    populationsize::Int = 100
    crossoverweight::Float32 = 1
    swapmutationweight::Float32 = 0.75
    identityweight::Float32 = 0.1 # One thing to remember is that, for simplicity, some of the other paths can lead to an unchanged keymap. So this weight doesn't need to be very high.
    replacepointmutationweight::Float32 = 0.25
    maxiter::Int = 100
    earlystopping::F = (currentscore::Float32, minscores::Vector{Float32}, minmin::Float32) -> begin
        percutoff = 0.9995
        if 1.01*minmin <= currentscore return false end
        nscores = 15
        if length(minscores) <= nscores return false end
        leftind = max(length(minscores)-nscores, 1)
        window = minscores[leftind:end]
        windowavg = mean(window)
        stopcond = percutoff * windowavg <= currentscore <= (2-percutoff)*windowavg
        if stopcond
            @info "Stopping at generation $(length(minscores)-1) since current score $currentscore is within 0.1% of average of previous $nscores min scores $windowavg."
        end
        return stopcond
    end
    replacementexclusions::Set{Keycode} = Commonreplacementexclusions
    selector::AbstractSolutionSelector = BestScoresSelector()

    CalculatorConfig(rdesc, p, c, s, i, r, m, e::F, re, sel) where {F <: Function} = new{F}(rdesc, p, c, s, i, r, m, e, re, sel)
end

function Base.show(io::IO, cc::T) where {T <: CalculatorConfig}
    for fname in fieldnames(T)
        println(io, fname, " = ", getfield(cc, fname))
    end
end

@kwdef mutable struct OperationCounter
    swapcount::Int = 0
    layerswitchswapcount::Int = 0
    replacecount::Int = 0
    identitycount::Int = 0
    identitycountcrossover::Int = 0
    crossovercount::Int = 0
end

mutable struct GeneticLayoutCalculator{S <: AbstractScoreFunction} <: AbstractLayoutCalculator
    calculatorconfig::CalculatorConfig
    scorefunction::S
end
calculatorconfig(glc::GeneticLayoutCalculator) = glc.calculatorconfig
scorefunction(glc::GeneticLayoutCalculator) = glc.scorefunction



function _rouletteselection(scores::Vector{T}, s1::T, s2::T) where {T <: Real}
    if s1 > s2 error("i1 should be <= i2") end
    i1 = 0
    i1wasset = false
    i2 = 0
    p = 0.0
    for i in eachindex(scores)
        currentscore = scores[i]
        p += currentscore
        if p > s1 && !i1wasset
            i1 = i 
            i1wasset = true
        end
        if p > s2 
            i2 = i 
            break
        end
    end
    return i1
end

function selectsolutionindex(rng::AbstractRNG, ars::RouletteSelector, scores::Vector{T}; selectionamount=:two) where {T <: Real}
    if length(scores) == 1 return 1, 1 end
    # @warn "Currently the roulette selection is being hardcoded to be inversely proportional to the score; add a toggle in case the objective changes." maxlog=1
    totalscore = sum(scores)
    invertedscores = totalscore .- scores
    invertedtotal = sum(invertedscores)
    s1 = rand(rng, T) * invertedtotal
    s2 = rand(rng, T) * invertedtotal
    # s1, s2 = min(s1, s2), max(s1, s2)
    if selectionamount == :one
        s2 = s1
    end
    return _rouletteselection(invertedscores, s1, s1), _rouletteselection(invertedscores, s2, s2)
end
# selectsolutionindex(ars::AbstractSolutionSelector, args...; kwargs...) = selectsolutionindex(default_rng(), ars, args...; kwargs...)
# selectsolutionindex(rng::AbstractRNG, args...; kwargs...) = selectsolutionindex(rng, RouletteSelector(), args...; kwargs...)
# selectsolutionindex(args...; kwargs...) = selectsolutionindex(default_rng(), RouletteSelector(), args...; kwargs...)

function selectsolutionindexes(rng::AbstractRNG, rs::RouletteSelector, scores::Vector{F}, i1::Int, i2::Int) where {F <: AbstractFloat}
    populationsize = length(scores)
    return map(x -> selectsolutionindex(rng, rs, scores), 1:populationsize)
end


function selectsolutionindexes(rng::AbstractRNG, bss::BestScoresSelector, scores::Vector{F}, currentit::Int, totalit::Int) where {F <: AbstractFloat}

    if currentit > totalit
        error("Error in setup, current iteration $currentit can't be greater than the total number of iterations $totalit.")
    end
    xs = bss.xs # 0   0.2   0.4  0.6  0.8   1.0
    ys = bss.ys # 1., 0.25, 0.5, 0.0, 0.25, 0.0
    
    populationsize = length(scores)
    sortedscoreinds = sortperm(scores)
    bestcutoff = Int(ceil(0.5(sqrt(8*populationsize + 1) + 1))) # (bestcutoff choose 2) ≈ popsize
    
    currentitperc = currentit / totalit
    # println(currentitperc)
    leftpoint = 1
    
    for bind in eachindex(xs)
        if bind == length(xs)
            leftpoint = bind
        elseif xs[bind] <= currentitperc < xs[bind+1]
            leftpoint = bind
            break
        end
    end
    
    y = ys[leftpoint]
    # println(y)
    solutionscutoff = bestcutoff + Int(ceil((populationsize - bestcutoff)*y))
    tupinds = Vector{Tuple{Int, Int}}(undef, populationsize)
    for i in 1:populationsize
        i1 = rand(rng, 1:solutionscutoff)
        i2 = rand(rng, 1:solutionscutoff)
        c = 0
        while i1 == i2
            if c >= 60 error("Somehow can't find distinct indices.") end
            i1 = rand(rng, 1:solutionscutoff)
            i2 = rand(rng, 1:solutionscutoff)
            c += 1
        end
        tupinds[i] = (sortedscoreinds[i1], sortedscoreinds[i2])
    end
    return tupinds
end


include("geneticmutations.jl")
include("geneticcrossovers.jl")


function _removeunusedkeys!(sf::AbstractScoreFunction, km::Keymap, frequencies::AbstractFrequencyHolder)
    usedkeylocs = Set{KeyLocation}()
    calculatescore(sf, km, frequencies, getngrams(frequencies); usedkeylocs=usedkeylocs)
    for layernum in eachindex(km)
        for rownum in eachindex(km[layernum])
            for colnum in eachindex(km[layernum][rownum])
                kl = KeyLocation(layernum, rownum, colnum)
                if kl in usedkeylocs || isspecialcase(km, kl) continue end
                km[kl] = Key()
            end
        end
    end
    return km
end

function _shortuuid()
    return string(uuid1())[1:8]
end


function _calculateinitialsolutions!(rng::AbstractRNG, sf::AbstractScoreFunction, keymap::K, frequencyholder::AbstractFrequencyHolder, validkeys::Vector{Keycode}, populationsize::Int, solutions::Vector{K}, scores::Vector{F}; symmetricshift=true, additionaltemplates::Union{Nothing, Vector{K}}=nothing, io::IO=IOContext(stdout, :color => true)) where {K <: AbstractKeymap, F <: AbstractFloat}
    ngramfrequencies = getngrams(frequencyholder)
    ri = rand(rng, 1:111111111111)
    rngs = [rng, (Xoshiro(ri + i) for i in 1:Threads.nthreads()-1)...]
    Threads.@threads for i in ProgressBar(1:populationsize)
        threadrng = rngs[Threads.threadid()]
        randkm = 
            if additionaltemplates === nothing
                first(genrandomkeymap(threadrng, keymap, validkeys; symmetricshift=symmetricshift))
            else
                # r = rand(rng, 1:1+length(additionaltemplates))
                first(genrandomkeymap(threadrng, append!([keymap],additionaltemplates)[rand(threadrng, 1:length(additionaltemplates)+1)], validkeys; symmetricshift=symmetricshift))
                # r = rand(rng)
                # if r <= 0.995
                #     first(genrandomkeymap(threadrng, keymap, validkeys; symmetricshift=symmetricshift))
                # else
                #     first(genrandomkeymap(threadrng, additionaltemplates[rand(threadrng, 1:length(additionaltemplates))], validkeys; symmetricshift=symmetricshift))
                # end
            end
        solutions[i] = randkm
        scores[i] = calculatescore(sf, randkm, frequencyholder, ngramfrequencies)
    end
    println(io, "An initial random keymap: \n", solutions[1], "\nwith corresponding score: ", scores[1])
    return solutions, scores
end

function calculatelayout(rng::AbstractRNG, lc::GeneticLayoutCalculator, keymap::K, frequencyholder::AbstractFrequencyHolder; symmetricshift=true, checkpointdir=_shortuuid(), additionaltemplates::Union{Nothing, Vector{K}}=nothing, io::IO=IOContext(stdout, :color => true)) where {K <: AbstractKeymap}
    @error "There is some error if the template keymap uses symmetric but non-shift keycodes." maxlog=1

    calcconfig = calculatorconfig(lc)

    # @info calcconfig.rundescription
    @info lc
    
    populationsize = calcconfig.populationsize
    sf = scorefunction(lc)
    maxiter = calcconfig.maxiter
    mutationweight = calcconfig.replacepointmutationweight + calcconfig.swapmutationweight + calcconfig.identityweight
    crossoverweight = calcconfig.crossoverweight
    numcrossovers = convert(Int, floor((crossoverweight / (crossoverweight + mutationweight)) * populationsize))
    uniquekeycodes = getuniquekeycodes(frequencyholder)
    validreplacements = filter(x -> !(x in calcconfig.replacementexclusions), deepcopy(uniquekeycodes))
    ngramfrequencies = getngrams(frequencyholder)
    selector = calcconfig.selector
    @logmsg MutationLogLevel "uniquekeycodes $uniquekeycodes"

    @info "Using $selector"


    if checkpointdir !== nothing
        mkdir("checkpoints/$checkpointdir")
        @info "Creating checkpoints/$checkpointdir"
        YAML.write_file("checkpoints/$checkpointdir/config.yml", lc)
    end

    solutions::Vector{K} = Vector{K}(undef, populationsize)
    scores = Vector{Float32}(undef, populationsize)

    checkauxlayersize(sf, keymap, effortlayer(keymap))
    if !isempty(fingermaplayer(keymap))
        checkauxlayersize(sf, keymap, fingermaplayer(keymap))
    end

    _calculateinitialsolutions!(rng, sf, keymap, frequencyholder, validreplacements, populationsize, solutions, scores; symmetricshift=symmetricshift, additionaltemplates=additionaltemplates, io=io)

    ri = rand(rng, 1:111111111111)
    rngs = [rng, (Xoshiro(ri + i) for i in 1:Threads.nthreads()-1)...]
    @Threads.threads for i in ProgressBar(1:populationsize)
        solutions[i] = swapmutation!(rngs[Threads.threadid()], lc, deepcopy(solutions[i]))
        # solutions[i] = swapmutation!(rngs[Threads.threadid()], lc, deepcopy(solutions[i]))
        # solutions[i] = swapmutation!(rngs[Threads.threadid()], lc, deepcopy(solutions[i]))
    end

    if checkpointdir !== nothing
        bestinitialsoln = solutions[argmin(scores)]
        jldsave("checkpoints/$checkpointdir/it0.jld2"; bestinitialsoln)
    end
    
    avgscores = Float32[mean(scores)]
    stdscores = Float32[std(scores)]
    minscores = Float32[minimum(scores)]
    maxscores = Float32[maximum(scores)]

    opcounts = OperationCounter()
    # @warn "When (genetic algorithm) mutating a keymap, currently deepcopying solution to deal with mutation problems." maxlog=1


    newsolutions::Vector{K} = Vector{K}(undef, populationsize)
    # newsolutionisfrom = Vector{String}(undef, populationsize)
    newscores = Vector{Float32}(undef, populationsize)
    # todo: refactor how solutions of next iteration and reassign to variable
    for it in ProgressBar(1:maxiter)
        if it == Int(floor(maxiter/3)) ||  it == Int(floor(2*maxiter/3))
            @info "Garbage collecting"
            GC.gc() 
        end
        @logmsg CounterLogLevel "before iteration $it $(solutions[1])"
        
        # rngs = [rng, (Xoshiro(ri + i) for i in 1:Threads.nthreads()-1)...]
        
        solutioninds = selectsolutionindexes(rng, selector, scores, it, maxiter)
        # won't be deterministic if using multiple threads due to scheduling I think?
        Threads.@threads for i in 1:populationsize
            @logmsg CounterLogLevel "\tsoln num $i" 
            # i1, i2 = selectsolutionindex(rngs[Threads.threadid()], selector, scores) # todo: selection algorithm as a part of the calculator config
            i1, i2 = solutioninds[i]
            if i <= numcrossovers
                # assume that the first arg is the one with the better score
                (soln1, soln2) = scores[i1] <= scores[i2] ? (solutions[i1], solutions[i2]) : (solutions[i2], solutions[i1])
                newsolutions[i] = crossover!(rngs[Threads.threadid()], deepcopy(soln1), deepcopy(soln2); opcounts = opcounts)
                # newsolutionisfrom[i] = "crossover"
            else
                # i1, i2 = selectsolutionindex(rngs[Threads.threadid()], RouletteSelector(), scores, selectionamount=:one)
                newsolutions[i] = mutate!(rngs[Threads.threadid()], lc, deepcopy(solutions[i1]), validreplacements; opcounts = opcounts, symmetricshift=symmetricshift)
                # newsolutionisfrom[i] = "mutation"
            end
            newscores[i] = calculatescore(sf, newsolutions[i], frequencyholder, ngramfrequencies)
        end
        
        solutions .= newsolutions
        scores .= newscores

        
        minind = argmin(scores)
        minsoln = solutions[minind]
        if checkpointdir !== nothing
            jldsave("checkpoints/$checkpointdir/it$it.jld2"; minsoln)
        end
        push!(avgscores, mean(scores))
        push!(stdscores, std(scores))
        push!(minscores, minimum(scores))
        push!(maxscores, maximum(scores))
        @logmsg CounterLogLevel "after iteration $it $(solutions[1])"
        currentminmin = minimum(minscores)
        if calcconfig.earlystopping(scores[argmin(scores)], minscores, currentminmin)
            break
        end
    end

    

    finalsoln = solutions[argmin(scores)]    
    _removeunusedkeys!(sf, finalsoln, frequencyholder)
    finalscore = calculatescore(sf, finalsoln, frequencyholder, ngramfrequencies)
    if finalscore != minscores[end] error("Removing unused keycodes messed up as scores pre- and post-removal don't match.") end

    minminid = argmin(minscores)

    println(io,"swap count: ", opcounts.swapcount, 
        ", layer switch swap count: ", opcounts.layerswitchswapcount, 
        ", identity count (mutations): ", opcounts.identitycount, 
        ", identity count (crossovers): ", opcounts.identitycountcrossover,
        ", replace count: ", opcounts.replacecount, 
        ", crossover count: ", opcounts.crossovercount)

    @info "final solution\n$finalsoln\ncorresponding score: $finalscore"
    @info "min of min score $(minimum(minscores)) occurs at index $minminid, which corresponds to iteration $(minminid-1) (index 1 is the initial solution, so index 2 is when iteration 1 starts)"

    if checkpointdir !== nothing
        minminkm = _removeunusedkeys!(sf, load_object("checkpoints/$checkpointdir/it$(minminid-1).jld2"), frequencyholder)
        minminscore = calculatescore(sf, minminkm, frequencyholder, ngramfrequencies)
        println(io, "min of min solution without unused keys\n$minminkm\ncorresponding score: $minminscore")
    end
    
    plt = lineplot(1:length(avgscores), hcat(avgscores, minscores), title="Scores", xlabel="Generation", name=["Avg scores", "Min scores"], color=[:green :cyan], width=60, canvas=DotCanvas, border=:ascii)
    # lineplot!(plt, 1:maxiter+1, minscores, name="Min scores", color=:cyan)
    println(io, plt)

    avgstr = string.(round.(avgscores, digits=2))
    stdstr = string.(round.(stdscores, digits=2))
    avgstdstr = "[" * join(avgstr .* " ± " .* stdstr, ", ") * "]"
    GC.gc()
    return finalsoln, avgstdstr, round.(minscores, digits=4), round.(maxscores, digits=4)
end
# calculatelayout(args...; kwargs...) = calculatelayout(default_rng(), args..., kwargs...)

