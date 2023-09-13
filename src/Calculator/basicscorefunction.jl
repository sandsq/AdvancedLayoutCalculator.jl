"""
    BasicScoreFunction
Very basic score function to test optimization.
"""
@kwdef struct BasicScoreFunction <: AbstractScoreFunction 
    description::String = ""
end

function scoresequence(bsf::BasicScoreFunction, km::AbstractKeymap, el::EffortLayer, fl::FingerMapLayer, seq::KeyLocationSequence)
    # el = effortlayer(km)
    # checkauxlayersize(bsf, km, el)
    prevlayer = 1
    totaleffort = 0.0
    @logmsg ScoringLogLevel "current sequence $seq"
    for kl in seq
        @logmsg ScoringLogLevel "\tcurrent key location in sequence is $kl"
        currentlayer = layernum(kl)
        currenteffort = el[kl]
        postoenterprevlayer = getpositiontoenterlayer(layerswitchmap(km), prevlayer)
        @logmsg ScoringLogLevel "\tposition to enter previous layer ($prevlayer) $postoenterprevlayer"
        # if the current key location (kl) is the key that switches to the previous layer, we don't need to include its effort 
        if postoenterprevlayer == kl
            # @logmsg debug "Layer switch was canceled out."
            continue
        end

        totaleffort += currenteffort
               
        @logmsg ScoringLogLevel "\t current score $totaleffort"
        prevlayer = currentlayer
    end
    return totaleffort
end


