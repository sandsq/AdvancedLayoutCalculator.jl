"""
    AdvancedScoreFunction
- `holdliftpenalty`: extra effort required to lift a layer switch key. This fraction of the layer switch effort value is added on to the base effort.
- `rollbonus`: reduced effort from rolls. Note that this uses column value rather than fingers -- see bigrambonus for similar reasoning
- `maxrolllength`: maximum length when considering rolls. Default to 5 since that would account for pinkie through thumb or vice versa. I think min can just be set to 3? Since bigrams are penalized for being the same finger there shouldn't be too much of a need to give bonus to bigram rolls.
- `samefingerpenalty`: penalty if consecutive keys use the same finger (on the same hand). The first of the keys retains its original effort value while the second key is multiplied by the penalty. Note that this does not account for the "slide", where you can slide a finger from an upper row to a lower row.
- `layerswitchcd`: after returning to the original layer, if a layer switch happens within this many keystrokes, incur extra penalty on the layer switch key
- `layerswitchpenalty`: extra factor of effort experienced
- `bigrambonus`: bonus if bigrams are next to each other. This value is multiplied by the bigram cost and subtracted from the total effort. Note that this will use the column values rather than the fingers -- this allows us to shift our hand over in order to use different fingers if necessary
- `multirowpenalty`: if consecutive keys move 2 or more rows, penalize
- `multirowmod`: if multi row change occurs as part of a roll, reduce the multirow penalty
"""
@kwdef struct AdvancedScoreFunction <: AbstractScoreFunction
    version::String = "0.1.0"
    description::String = ""
    holdliftpenalty::Float32 = 2.0
    rollbonus::Float32 = 0.5
    maxrolllength::Int = 4
    samefingerpenalty::Float32 = 3.0
    layerswitchcd::Int = 4
    layerswitchpenalty::Float32 = 3.0
    bigrambonus::Float32 = 0.3
    multirowpenalty::Float32 = 2.0
    multirowmod::Float32 = 0.5
end

function Base.show(io::IO, advsf::T) where {T <: AdvancedScoreFunction}
    for fname in fieldnames(T)
        println(io, fname, " = ", getfield(advsf, fname))
    end
end

function checkfingerroll(fings::Vector{Finger})
    # total = 0
    total = length(fings) - 1
    ltcount = 0
    gtcount = 0
    for find in 2:length(fings)
        fingpair = (@view fings[find-1:find])
        if fingpair[1] < fingpair[2] ltcount += 1 end
        if fingpair[1] > fingpair[2] gtcount += 1 end
    end
    if ltcount == total || gtcount == total return true end
    return false
end

"""
    checkcolroll
Either monotonically increasing or decreasing (strict)
"""
function checkcolroll(cols::Vector{Int})
    # total = 0
    total = length(cols) - 1
    ltcount = 0
    gtcount = 0
    for find in 2:length(cols)
        colpair = (@view cols[find-1:find])
        if colpair[1] < colpair[2] ltcount += 1 end
        if colpair[1] > colpair[2] gtcount += 1 end
    end
    if ltcount == total || gtcount == total return true end
    return false
end

function findnunique(a)
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

"""
    checkrowroll
monotonically increasing (not strict)
Note that since the ordering of rows is opposite that of columns, we are actually checking for a decreasing sequence.
Also, this only works for one hand (left), as we would want the opposite trend for right hands.
"""
function checkrowroll(rows::Vector{Int})
    total = length(rows) - 1
    gtcount = 0
    for find in 2:length(rows)
        rowpair = (@view rows[find-1:find])
        if rowpair[1] >= rowpair[2] gtcount += 1 end
    end
    if gtcount == total return true end
    return false
end

"""
    isroll
Roll conditions:
- same hand
- cols monotonically increase or decrease (strictly)
- rows monotonically change in the same direction as cols (not strictly)
not considered:
- inner roll (rolling toward the center) may have different favorability compared to an outer roll
- negative slope paths are not considered rolls due to hand shape. May revisit in the future, especially if rowspan is small.
    - I think finger matters as well; ring, middle, index works if ring and middle are the same row.
- these rules apply to left hand, but not right hand (currently not optimizing for dual hand so not a huge problem).
"""
function isroll(rowseq::Vector{Int}, colseq::Vector{Int}, handfings::Vector{Tuple{Hand, Finger}})
    if !allequal(first.(handfings)) return false end # if not all on the same hand, not a roll

    # columns either increase or decrease
    if !checkcolroll(colseq) return false end

    # arrange position in terms of increasing columns
    colorder = sortperm(colseq)
    rowseq = rowseq[colorder]
    colseq = colseq[colorder]

    if checkrowroll(rowseq) return true end

    return false
end

function cancells(advsf::AdvancedScoreFunction, km::AbstractKeymap, fl::FingerMapLayer, seq::KeyLocationSequence)
    usepositions = ones(Bool, length(seq))
    for (sind, loc) in enumerate(seq)
        # @info value(km[loc])
        if value(km[loc]) == _LS && usepositions[sind]
            for newinds in sind+2:2:length(seq)
                if seq[newinds] == loc
                    usepositions[newinds] = false
                end
            end
            for newinds in sind+3:2:length(seq)
                if fl[seq[newinds]] == fl[loc] # 
                    usepositions[newinds-1] = true
                end
            end
        end
    end
    newseq = KL[]
    for (posind, usepos) in enumerate(usepositions)
        if usepos
            push!(newseq, seq[posind])
        end
    end
    return KeyLocationSequence(newseq)
end

function scoresequence(advsf::AdvancedScoreFunction, km::AbstractKeymap, el::EffortLayer, fl::FingerMapLayer, seq::KeyLocationSequence)

    # @logmsg currentdebuglevel seq
    # @info "seq before $seq"
    seq = cancells(advsf, km, fl, seq)
    # @info "seq after $seq"

    totaleffort = 0.0
    rollvisited = zeros(Bool, length(seq))
    samefingvisited = zeros(Bool, length(seq))
    multirowvisited = zeros(Bool, length(seq))
    maxrolllength = advsf.maxrolllength
    minrolllength = 3
    rollbonus = advsf.rollbonus
    bigrambonus = advsf.bigrambonus
    effort = 0.0
    currenteffort = 0.0
    samefingerpenalty = advsf.samefingerpenalty
    multirowmod = advsf.multirowmod
    
    for rolln in Iterators.reverse(minrolllength:maxrolllength)
        if length(seq) < rolln continue end
        for seqind in 1:length(seq)-rolln+1
            tailind = seqind+rolln-1
            if sum((@view rollvisited[seqind:tailind])) != 0 continue end # if not 0, then some of the locations have already been visited
            partialseq = (@view seq[seqind:tailind])
            handfings = (x -> fl[x]).(partialseq)
            if sum((@view samefingvisited[seqind:tailind])) == 0 && allequal(handfings)
                effort = sum(x -> el[x], partialseq) * samefingerpenalty^(length(handfings)-1)
                totaleffort += effort
                samefingvisited[seqind:tailind] .= true
            end


            # if !allequal(first.(handfings)) continue end # if not all on the same hand, not a roll
            # rowseq = first.(gridposition.(partialseq))

            # nunirows = findnunique(sort!(rowseq))
            # rowspan = rowseq[end] - rowseq[1]
            # if !(nunirows <= 2 && rowspan <= 1) continue end # maximum 2 different rows and at most one row away

            rowseq = first.(gridposition.(partialseq))
            colseq = (x -> x[2]).(gridposition.(partialseq))

            if isroll(rowseq, colseq, handfings)
                effort = sum(x -> el[x], partialseq) * rollbonus^(rolln-minrolllength+1)
                totaleffort -= effort
                rollvisited[seqind:tailind] .= true
            end
        end
    end

    # @logmsg currentdebuglevel "after roll checks $totaleffort"

    # bigrams
    for seqind in 1:length(seq)-2+1
        multirowpenalty = advsf.multirowpenalty
        tailind = seqind+2-1
        partialseq = (@view seq[seqind:tailind])
        handfings = (x -> fl[x]).(partialseq)
        if sum((@view samefingvisited[seqind:tailind])) == 0 && allequal(handfings)
            effort = sum(x -> el[x], partialseq) * samefingerpenalty
            totaleffort += effort
            samefingvisited[seqind:tailind] .= true
        end
        rowseq = first.(gridposition.(partialseq))
        nunirows = findnunique(sort!(rowseq))
        rowspan = rowseq[end] - rowseq[1]

        paireffort = sum(x -> el[x], partialseq)
        
        if rowspan >= 2 && !(thumb in (x -> x[2]).(handfings))
            if sum((@view rollvisited[seqind:tailind])) == 2
                multirowpenalty = max(1, 1 + (multirowpenalty - 1) * multirowmod)
            end
            if !multirowvisited[seqind] && !multirowvisited[tailind] # have not visited anything
                totaleffort += paireffort * multirowpenalty^(rowspan-1)
                multirowvisited[seqind:tailind] .= true
            elseif multirowvisited[seqind] && multirowvisited[tailind] # have not visited location 1
                totaleffort += el[partialseq[1]] * multirowpenalty^(rowspan-1)
                multirowvisited[seqind] = true
            elseif multirowvisited[seqind] && !multirowvisited[tailind] # have not visited location 2
                totaleffort += el[partialseq[2]] * multirowpenalty^(rowspan-1)
                multirowvisited[tailind] = true
            end
        end

        if nunirows != 1 continue end

        colseq = (x -> x[2]).(gridposition.(partialseq))
        if abs(colseq[1] - colseq[2]) == 1
            # effort is subtracted -- we are not checking for visitation as we want this bonus to be applied to everything. However, the effort of the bigram is already being applied via the rolls so we don't want to double count by adding a fraction of the effort.
            # note that this include neighors across layers as well, which should be fine
            # todo: similar application for roll bonus, where rolls subtract a portion of their effort and the roll is counter later in the main loop through the sequence (rather than keeping track of the fact that a roll has been visited)?
            # todo: potentially want to exclude layer switches?
            totaleffort -= paireffort * bigrambonus
        end
        # continue
        # @logmsg currentdebuglevel totaleffort
    end

    # @logmsg currentdebuglevel " after bigram checks $totaleffort"
    
    holdliftpenalty = advsf.holdliftpenalty
    layerswitchcd = advsf.layerswitchcd
    layerswitchpenalty = advsf.layerswitchpenalty

    prevlocs = KeyLocation[]
    currentcd = 0
    for (sind, kl) in enumerate(seq)
        
        prevlayer = length(prevlocs) == 0 ? 1 : layernum(prevlocs[end])
        currentlayer = layernum(kl)
        currenteffort = el[kl]

        
        if value(km[kl]) == _LS
            if currentcd > 0
                totaleffort += currenteffort*layerswitchpenalty
            end
            currentcd = layerswitchcd
        end

        # @info "ls cooldown $totaleffort"

        # if the current key location (kl) is the key that switches to the previous layer, we don't need to include its effort since the assumption is that you're still holding it down
        postoenterprevlayer = getpositiontoenterlayer(layerswitchmap(km), prevlayer)
        if postoenterprevlayer == kl
            continue
        end

        if sind >= 2 && !samefingvisited[sind]
            # if consecutive keys use the same hand and finger and the second key isn't already part of a chain (i.e., sequences of 5 keys with the same finger), incur penalty
            if fl[kl] == fl[seq[sind-1]] 
                totaleffort += currenteffort * samefingerpenalty
            end
        end

        # @info "same fing $samefingvisited $totaleffort"
        
        # if !visited[sind]
        totaleffort += currenteffort    
        # end

        # if moving down a layer (uses assumption that layer changes only go from lower to higher)
        if currentlayer < prevlayer
            layerposeffort = el[postoenterprevlayer]
            liftpenalty = layerposeffort * holdliftpenalty
            totaleffort += liftpenalty
        end
    
        # @info "hold lift $totaleffort"

        push!(prevlocs, kl)
        currentcd -= 1
        
        # @logmsg ScoringLogLevel totaleffort
        # @info totaleffort
    end
    return totaleffort
end