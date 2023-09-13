module DummyKeyboard
    using Random
    import Random: default_rng
    using Statistics
    using Distributed
    using Logging

    export
        calculatething
    

    struct Straw 
        straw::Float32
    end
    # function Base.show(io::IO, s::Straw)
    #     println(io, "lalala ", s.straw*2)
    # end

    struct SpecialInd
        i::Int
    end
    spind(si::SpecialInd) = si.i
    # Base.show(io::IO, sp::SpecialInd) = print(io, spind(sp))

    struct Layer
        layer::Vector{Int}
    end
    layer(l::Layer) = l.layer
    Base.eachindex(l::Layer) = Base.OneTo(length(layer(l)))
    Base.length(l::Layer) = length(layer(l))
    # function Base.show(io::IO, l::Layer)
    #     println(io, layer(l)[1])
    # end

    function randinds(rng::AbstractRNG, numcols)
        return SpecialInd(rand(rng, 1:numcols)), SpecialInd(rand(rng, 1:numcols))
    end
    randinds(args...; kwargs...) = randinds(default_rng(), args...; kwargs...)

    function randlayer(rng::AbstractRNG, numcols::Int, pool::Vector{Int})
        poolcopy = deepcopy(pool)
        shuffle!(rng, poolcopy)
        out = Int[]
        for i in 1:numcols
            if length(poolcopy) == 0
                push!(out, -1)
            else
                push!(out, pop!(poolcopy))
            end
        end
        return Layer(out), poolcopy
    end
    randlayer(args...; kwargs...) = randlayer(default_rng(), args...; kwargs...)

    function randkeymap(rng::AbstractRNG, numlayers::Int, numcols::Int, pool::Vector{Int})
        keymap = Vector{Layer}()
        poolcopy = deepcopy(pool)
        shuffle!(rng, poolcopy)
        for i in 1:numlayers
            l, poolcopy = randlayer(rng, numcols, poolcopy)
            push!(keymap, l)
        end
        return keymap
    end
    randkeymap(args...; kwargs...) = randkeymap(default_rng(), args...; kwargs...)

    function scorething(km::Vector{Layer})
        score = 0.0
        for rowi in eachindex(km)
            row = km[rowi]
            for coli in eachindex(row)
                score += ((rowi - 1) * length(row) + coli) * layer(km[rowi])[coli]
            end
        end
        return score
    end

    function calculatething(rng::AbstractRNG)
        stra = Straw(0.5)
        @debug stra
        pooldict = Dict{Int, Int}(1 => 1, 2 => 2, 4 => 4, 3 => 3, 5 => 5, 6 => 6, 7 => 7, 8 => 8, 9 => 9, 10 => 10, 11 => 11, 12 => 12)
        keymaps = map(1:100) do i
            randkeymap(rng, 2, 4, collect(keys(pooldict)))
        end
        avgscores = Float32[]
        for it in 1:100
            @debug "iter num $it"
            newkeymaps = map(1:100) do i
                @debug "\tsoln num $i"
                @debug "filler"
                km = deepcopy(keymaps[i])
                x1, x2 = randinds(rng, 4)
                @debug "swapping 1, $x1 with 2, $x2"
                v1 = layer(km[1])[spind(x1)]
                v2 = layer(km[2])[spind(x2)]
                km[1].layer[spind(x1)] = v2
                km[2].layer[spind(x2)] = v1
                km
            end
            newscores = map(1:100) do i
                scorething(newkeymaps[i]) * stra.straw
            end
            keymaps = newkeymaps
            scores = newscores
            @debug "\t$keymaps"
            push!(avgscores, mean(scores))
        end
        println(avgscores)
        
        return keymaps
    end
    calculatething(args...; kwargs...) = calculatething(default_rng(), args...; kwargs...)

end # module


using .DummyKeyboard
using Random
using Logging
rng = Xoshiro(1)
newdebuglogger = ConsoleLogger(stdout, Logging.Debug)
with_logger(newdebuglogger) do
    calculatething(rng)
end



function _rouletteselection(scores::Vector{T}, s1::T, s2::T) where {T <: Real}
    if s1 > s2 error("i1 should be <= i2") end
    i1 = 0
    i2 = 0
    p = 0.0
    for i in eachindex(scores)
        currentscore = scores[i]
        p += currentscore
        if p > s1 i1 = i end
        if p > s2 
            i2 = i 
            break
        end
    end
    return i1, i2
end



probarr = [0.1, 0.3, 0.4, 0.2]
inds = [0, 0, 0, 0]
for i in 1:10000000
    r = rand()*3
    i = first(_rouletteselection(sum(probarr) .- probarr, r, r))
    inds[i] += 1
end
println(inds)

# [234.51, 234.92, 237.2, 234.75, 232.57, 233.64, 232.25, 236.0, 233.1, 234.23, 231.41, 233.37, 234.79, 230.59, 230.4, 229.1, 233.42, 231.18, 229.06, 233.9, 233.49, 232.33, 232.07, 234.09, 232.6, 233.24, 234.67, 230.9, 229.13, 232.0, 230.52, 230.66, 229.27, 229.65, 229.44, 231.41, 231.66, 231.79, 231.14, 233.59, 233.17, 231.68, 230.29, 232.73, 234.33, 232.08, 233.11, 231.67, 231.59, 232.79, 230.99, 229.54, 229.68, 230.13, 232.68, 233.14, 231.99, 233.29, 231.77, 234.63, 235.44, 234.65, 231.34, 229.65, 230.32, 229.6, 229.27, 232.52, 232.76, 234.1, 231.29, 232.31, 231.74, 232.74, 231.68, 231.5, 233.63, 231.69, 232.23, 234.16, 234.38, 233.81, 231.86, 232.16, 232.09, 231.75, 228.75, 228.15, 230.52, 231.57, 234.03, 236.13, 233.25, 231.08, 230.7, 231.31, 231.78, 231.14, 231.74, 234.44]
