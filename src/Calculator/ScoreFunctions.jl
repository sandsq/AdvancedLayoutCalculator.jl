module ScoreFunctions

using AdvancedLayoutCalculator
using AdvancedLayoutCalculator.Keyboard
using AdvancedLayoutCalculator.AlcUtils
using AdvancedLayoutCalculator.TextProcessor
using Logging
using Random

export
    AbstractScoreFunction,
    checkauxlayersize,
    BasicScoreFunction,
    scoresequence,
    calculatescore,
    AdvancedScoreFunction

"""
    AbstractScoreFunction
Represents functions that score a `Keymap` based on key position effort and `Keycode` frequencies.
"""
abstract type AbstractScoreFunction end

"""
    scoresequence
Scores a KeyLocationSequence based on scorefunction selected.
"""
scoresequence(asf::AbstractScoreFunction, km::AbstractKeymap, el::EffortLayer, seq::KeyLocationSequence) = error("scoresquence($(typeof(asf)), $(typeof(km)), $(typeof(el)), $(typeof(seq))) not implemented.")

"""
    checkeffortmapsize(sf, keymap, effortmap)
Checks to make sure the keymap and the effortmap have compatible sizes.
"""
function checkauxlayersize(asf::AbstractScoreFunction, km::AbstractKeymap, aux::Union{EffortLayer, FingerMapLayer})
    if dimensionsgran(baselayer(km)) != dimensionsgran(aux)
        error("The keymap ($(dimensionsgran(baselayer(km)))) and the effortmap/fingermap ($(dimensionsgran(aux))) need to be the same shape.")
    end
    return nothing
end

function _addtobranch(asf::AbstractScoreFunction, branches::Vector{KeyLocationSequence}, leaves::Vector{KeyLocationSequence})
    newbranches = Vector{KeyLocationSequence}()
    if length(branches) == 0
        push!(branches, KeyLocationSequence())
    end
    for branch in branches
        for leaf in leaves
            isnothing(branch) ? push!(newbranches, leaf) : push!(newbranches, vcat(branch, leaf))
        end
    end
    return newbranches
end

include("basicscorefunction.jl")
include("advancedscorefunction.jl")

function calculatescore(bsf::AbstractScoreFunction, keymap::AbstractKeymap, frequencyholder::AbstractFrequencyHolder, ngramfrequencies::S; usedkeylocs=nothing) where {S <: AbstractSet{Ngram}}
    el = effortlayer(keymap)
    fl = fingermaplayer(keymap)
    score::Float32 = 0.0
    minscoreofseqs::Float32 = 0.0
    # @warn "It might be dangerous to examine all possible paths for a certain ngram, but given practical keyboard sizes it's probably ok." maxlog=1
    # @logmsg ScoringLogLevel "ngrams $ngramfrequencies" #$(getngrams(frequencyholder))"
    for ngram in ngramfrequencies # getngrams(frequencyholder)
        possibleseqs = KeyLocationSequence[]
        for keycode in ngram
            seqs = keymap[keycode]
            possibleseqs = _addtobranch(bsf, possibleseqs, seqs)
        end
        # it seems to be slightly faster to pass the effortlayer in as an arg rather than access it inside
        minscoreofseqs, minind = findmin(x -> scoresequence(bsf, keymap, el, fl, x), possibleseqs)
        if usedkeylocs !== nothing #typeof(usedkeylocs) == Set{KeyLocation}
            minseq = possibleseqs[minind]
            for loc in minseq
                push!(usedkeylocs, loc)
            end
        end
        # @logmsg ScoringLogLevel "sequences $possibleseqs, score $minscoreofseqs * $(frequencyholder[ngram])"
        score += minscoreofseqs * frequencyholder[ngram]
    end
    return score
end



end # module