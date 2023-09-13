function layerswitchswapmutation!(rng::AbstractRNG, lc::GeneticLayoutCalculator, km::Keymap; opcounts = OperationCounter())
    @logmsg KeymapLogLevel "pre layer switch swap\n$km"
    layerswitchlocations = locations(layerswitchmap(km))
    chosentargetlayernum = rand(rng, 1:length(layerswitchlocations)-1) + 1
    chosensourceposition = layerswitchlocations[chosentargetlayernum]
    chosensourcelayernum = layernum(chosensourceposition)
    chosentargetposition = KeyLocation(chosentargetlayernum, gridposition(chosensourceposition))
    @logmsg MutationLogLevel "$chosensourceposition ($(value(km[chosensourceposition]))) has $chosentargetposition ($(value(km[chosentargetposition]))) above it"
    if !ismoveable(km[chosensourceposition]) || !ismoveable(km[chosentargetposition])
        opcounts.identitycount += 1
        return km
    end
    if value(km[chosensourceposition]) != _LS || value(km[chosentargetposition]) != _LS
        error("$chosensourceposition is $(km[chosensourceposition]), $chosentargetposition is $(km[chosentargetposition]), both should be _LS otherwise there is probably an issue with the keymap setup.\n$km")
    end
    randsourceloc = genrandomloc(rng, km; layernum = chosensourcelayernum)
    randtargetloc = KeyLocation(chosentargetlayernum, gridposition(randsourceloc))
    if !ismoveable(km[randsourceloc]) || !ismoveable(km[randtargetloc]) || issymmetric(km[randsourceloc]) || issymmetric(km[randtargetloc])
        opcounts.identitycount += 1
        # @info "Can't find moveable, non-symmetric keys to switch with across the two layers, doing nothing instead." maxlog=1
        return km
    end
    if value(km[randsourceloc]) == _LS || value(km[randtargetloc]) == _LS
        opcounts.identitycount += 1
        # @info "Trying to swap layer switch with layer switch, either redundant or not allowed so doing nothing instead." maxlog=1
        return km
    end
    @logmsg MutationLogLevel "swapping $chosensourceposition ($(value(km[chosensourceposition]))) with $randsourceloc ($(value(km[randsourceloc]))) and $chosentargetposition ($(value(km[chosentargetposition]))) with $randtargetloc ($(value(km[randtargetloc])))"
    swapkeys!(km, chosensourceposition, randsourceloc)
    swapkeys!(km, chosentargetposition, randtargetloc)
    @logmsg KeymapLogLevel "post layer switch swaps\n$km"
    opcounts.layerswitchswapcount += 1
    newlayerswitchlocations = KeyLocation[]
    for (lind, ls) in enumerate(layerswitchlocations)
        if lind == chosentargetlayernum
            push!(newlayerswitchlocations, randsourceloc)
        else
            push!(newlayerswitchlocations, ls)
        end
    end
    # km = Keymap(layers(km); layerswitches = LayerSwitchmap(newlayerswitchlocations))
    newlsm = LayerSwitchmap(newlayerswitchlocations)
    # todo: setting method for this, instead of accessing fields directly
    km.layerswitchmap = newlsm
    km.keypathmap, km.specialcases = genkeypathmap(km, newlsm)


    @logmsg KeymapLogLevel "post reforming with layer switches\n$km"


    return km
end

function swapmutation!(rng::AbstractRNG, lc::GeneticLayoutCalculator, km::Keymap; opcounts = OperationCounter())
    randloc1 = genrandomloc(rng, km) # reminder: does not generate a non-moveable location
    randloc2 = genrandomloc(rng, km)
    if value(km[randloc1]) == _LS || value(km[randloc2]) == _LS
        # @info "Swapping a layer switch, going to specialized function." maxlog=1
        return layerswitchswapmutation!(rng, lc, km; opcounts=opcounts)
    end
    randloc1symm = getsymmetriclocation(randloc1, km)
    randloc2symm = getsymmetriclocation(randloc2, km)
    if issymmetric(km[randloc1]) && issymmetric(km[randloc2]) && ismoveable(km[randloc1]) && ismoveable(km[randloc2])
        swapkeys!(km, randloc1, randloc2)
        swapkeys!(km, randloc1symm, randloc2symm)
        opcounts.swapcount += 1
        return km
    end

    # make it so that randloc1 is the symmetric one
    randloc1, randloc2, randloc1symm, randloc2symm, swapped = issymmetric(km[randloc2]) ? (randloc2, randloc1, randloc2symm, randloc1symm, true) : (randloc1, randloc2, randloc1symm, randloc2symm, false)
    if issymmetric(km[randloc1])
        c = 0
        # randloc1 is symmetric, and if it was chosen it must be moveable, so randloc1symm will be moveable
        # randloc2 is not symmetric, meaning randloc2symm could be immovable
        # note: randloc2 will always be moveable since that's how genrandomloc works
        # randloc1 cannot be _LS as that is caught by an earlier condition. randloc2 could be _LS since it might be regenerated
        while !ismoveable(km[randloc2symm]) || value(km[randloc2symm]) == _LS || value(km[randloc2]) == _LS
            randloc2 = genrandomloc(rng, km)
            randloc2symm = getsymmetriclocation(randloc2, km)
            c += 1
            if c >= 60
                # @info "Unable to find symmetric, moveable, non-layer switch positions even after 60 iterations, leaving keymap unchanged." maxlog=1
                opcounts.identitycount += 1
                return km
            end
        end

        # ind = findfirst(x -> x == randloc1, specialcases(km))
        # specialcases(km)[ind] = randloc2
        # indother = findfirst(x -> x == randloc1symm, specialcases(km))
        # specialcases(km)[indother] = randloc2symm

        swapkeys!(km, randloc1symm, randloc2symm)
                
        # delete!(specialcases(km), randloc1symm)
        # push!(specialcases(km), randloc2symm)

        # delete!(specialcases(km), randloc1)
        # push!(specialcases(km), randloc2)
    end


    @logmsg MutationLogLevel "Swapping $randloc1 with $randloc2"
    swapkeys!(km, randloc1, randloc2)
    opcounts.swapcount += 1


    
    
    @logmsg KeymapLogLevel "after regular swapping\n$km"

    return km
end

function replacementpointmutation!(rng::AbstractRNG, lc::GeneticLayoutCalculator, km::Keymap, validkeys::Vector{Keycode}; opcounts = OperationCounter(), symmetricshift=true)
    # todo: make probability of new key (ie duplicate) being added inversely proportional to how many of that key are already present
    # or, make probability of a duplicate proportional to the effort off it / effort of already existing keys. For example, if we try to add _E to a high effort spot and existing _E's are low effort, there is a low chance of that happening. But if we try to add _E to a low effort spot and existing _E's are high effort, there is a high chance of that happening. Basically don't want too many dupes floating around.
    # also can just lower the weight for replacements
    @logmsg KeymapLogLevel "before replacement\n$km"
    randloc = genrandomloc(rng, km)
    keytoreplace = km[randloc]
    if value(keytoreplace) == _LS
        # @info "Cannot replace a layer switch, doing nothing." maxlog=1
        opcounts.identitycount += 1
        return km
    end
    c = 0
    while !canreplacekeytypeability(km, value(keytoreplace)) || issymmetric(keytoreplace) || value(keytoreplace) == _LS 
        randloc = genrandomloc(rng, km)
        keytoreplace = km[randloc]
        c += 1
        if c >= 60
            # @info "Unable to find a non-symmetric, non-layer switch key that can be replaced while keeping all keycodes typeable, even after 60 tries; doing nothing." maxlog=1
            opcounts.identitycount += 1
            return km
        end
    end
    @logmsg MutationLogLevel "Replacing $randloc"
    randind = rand(rng, 1:length(validkeys))
    randreplacement = validkeys[randind]
    if randreplacement == _SFT && symmetricshift
        # @warn "Currently unable to add _SFT (symmetric key) due to complexity." maxlog=1
        opcounts.identitycount += 1
        return km
        randlocsymm = getsymmetriclocation(randloc, km)
        keytoreplacesymm = km[randlocsymm]
        if ismoveable(km[randloc]) && ismoveable(km[randlocsymm]) && canreplacekeytypeability(km, value(keytoreplacesymm)) 
            if value(keytoreplace) == value(keytoreplacesymm) && canreplacekeytypeability(km, value(keytoreplace); minpaths=2)

            else
                opcounts.identitycount += 1
                # @info "Both symmetric positions have the same keycode, so if they are both replaced the we won't be able to type everything anymore. So, just doing nothing." maxlog=1
                return km
            end
            km[randloc] = Key(_SFT, true, true)
            km[randlocsymm] = Key(_SFT, true, true)
            opcounts.replacecount += 1
            @logmsg MutationLogLevel "Replacing $(value(keytoreplace)) with _SFT and symmetrically $(value(keytoreplacesymm)) with _SFT"
            @logmsg MutationLogLevel "keypathmap size $(length(keys(keypathmap(km)))), $(keys(keypathmap(km))) vs valid key size $(length(Set(validkeys))), $(Set(validkeys)), cantype $(cantype(km, Set(validkeys)))"
        else
            # @info "Unable to replace due to symmetric moveability / typeability constraints, doing nothing." maxlog=1
            opcounts.identitycount += 1 
        end
    else
        km[randloc] = Key(randreplacement)
        opcounts.replacecount += 1
    end
    @logmsg KeymapLogLevel "after replacement\n$km"
    return km
end

function mutate!(rng::AbstractRNG, lc::GeneticLayoutCalculator, km::Keymap, validkeys::Vector{Keycode}; opcounts = OperationCounter(), symmetricshift=true)

    calcconfig = calculatorconfig(lc)
    # todo: check symmetric positions of loc1 and loc2 (layer and keymap function that retrieves symmetric position?)
    swapweight = calcconfig.swapmutationweight
    identityweight = calcconfig.identityweight
    replaceweight = calcconfig.replacepointmutationweight
    
    totalweight = swapweight + identityweight + replaceweight
    newswapweight = swapweight / totalweight
    newidentityweight = identityweight / totalweight
    newreplaceweight = replaceweight / totalweight

    

    roll = rand(rng)
    if 0 <= roll < newswapweight
        swapmutation!(rng, lc, km; opcounts=opcounts)
    elseif newswapweight <= roll < newswapweight + newidentityweight
        @logmsg MutationLogLevel "Not changing"
        opcounts.identitycount += 1
    elseif newswapweight + newidentityweight <= roll <= newswapweight + newidentityweight + newreplaceweight
        replacementpointmutation!(rng, lc, km, validkeys; opcounts=opcounts, symmetricshift=symmetricshift)
    end



    return km
end
mutate!(args...; kwargs...) = mutate!(default_rng(), args...; kwargs...)


const Keycodeforpermutation = Tuple{Union{Keycode, Nothing}, Int}


"""
    isspecialcase
If a key is immoveable or symmetric or a layer switch, it is handled separately
"""
isspecialcase(km::AbstractProtoKeymap, kl::KeyLocation) = !ismoveable(km[kl]) || issymmetric(km[kl]) || value(km[kl]) == _LS
