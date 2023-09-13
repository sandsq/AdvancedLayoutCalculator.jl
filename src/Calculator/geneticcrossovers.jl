
"""
    _movelayerswitchesfrom1to2!
Assumes km1 has the better score. Returns km2, the changed keymap, and a boolean indicating if the crossover should proceed. The crossover will not proceed if layer switch moving needs to happen but it tries to move a symmetric location (as this is more complicated to handle (is it even possible?)).
"""
function _movelayerswitchesfrom1to2!(km1::Keymap, km2::Keymap)

    lsm1 = layerswitchmap(km1)
    lsm2 = layerswitchmap(km2)
    if lsm1 == lsm2 return km2, true end
    layerswitchlocs1 = locations(lsm1)
    layerswitchlocs2 = locations(lsm2)
    
    switchpairs = OrderedSet()
    for locind in Iterators.drop(eachindex(layerswitchlocs1), 1)
        lowerloc1 = layerswitchlocs1[locind]
        higherloc1 = KeyLocation(locind, gridposition(lowerloc1))

        lowerloc2 = layerswitchlocs2[locind]
        higherloc2 = KeyLocation(locind, gridposition(lowerloc2))
        push!(switchpairs, ((lowerloc1, lowerloc2), (higherloc1, higherloc2)))
    end

    counter = 0
    while length(switchpairs) > 0
        if counter >= 60
            # @warn "Collision of layer swiches on lower layers will cause positions to be disjointed, doing nothing." maxlog=1
            return km2, false
        end
        pairs = popfirst!(switchpairs)
        ((lowerloc1, lowerloc2), (higherloc1, higherloc2)) = pairs

        lower1 = value(km2[lowerloc1])
        lower2 = value(km2[lowerloc2])
        higher1 = value(km2[higherloc1])
        higher2 = value(km2[higherloc2])

        if value(km1[lowerloc1]) != _LS || value(km1[higherloc1]) != _LS || value(km2[lowerloc2]) != _LS || value(km2[higherloc2]) != _LS 
            error("Layer switches not found in expected location, something messed up.") 
        end

        if issymmetric(km2[lowerloc1]) || issymmetric(km2[higherloc1]) 
            # @warn "When trying to move layer switch locations from km1 to km2, encountered symmetric keys. Doing nothing." maxlog=1
            return km2, false
        end
        
        # loc2s are LS in km2
        if count(x -> x == _LS, [lower1, lower2, higher1, higher2]) == 3
            push!(switchpairs, pairs)
        else
            swapkeys!(km2, lowerloc1, lowerloc2)
            swapkeys!(km2, higherloc1, higherloc2)
        end
        counter += 1
    end

    km2.layerswitchmap = lsm1
    km2.keypathmap, km2.specialcases = genkeypathmap(km2, lsm1)

    return km2, true
end




"""
    _movesymmetrics1to2!
Assumes km1 has the better score. Returns the changed keymap km2 with any symmetric keys moved to their km1 locations.
"""
function _movesymmetrics1to2!(km1::Keymap, km2::Keymap)

    leftkeysloc1 = KeyLocation[]
    rightkeysloc1 = KeyLocation[]
    keys1 = Keycode[]
    leftkeysloc2 = KeyLocation[]
    rightkeysloc2 = KeyLocation[]
    keys2 = Keycode[]

    cutoff = Int(ceil(dimensions(baselayer(km1))[2]/2))

    for kl in union(specialcases(km1), specialcases(km2))
        if gridposition(kl)[2] > cutoff continue end


        if issymmetric(km1[kl])
            klsymm = getsymmetriclocation(kl, km1)
            if km1[kl] == km2[kl]
                continue
            end
            push!(leftkeysloc1, kl)
            push!(keys1, value(km1[kl]))
            if !issymmetric(km1[klsymm]) #|| value(km1[kl]) != value(km1[klsymm])
                error("Symmetric key $(value(km1[kl])) at $kl has been disjointed from key $(value(km1[klsymm])) at $klsymm")
            end
            push!(rightkeysloc1, klsymm)
        end

        if issymmetric(km2[kl])
            push!(leftkeysloc2, kl)
            push!(keys2, value(km2[kl]))
            klsymm = getsymmetriclocation(kl, km2)
            if !issymmetric(km2[klsymm]) #|| value(km2[kl]) != value(km2[klsymm])
                error("Symmetric key $(value(km2[kl])) at $kl has been disjointed from key $(value(km2[klsymm])) at $klsymm")
            end
            push!(rightkeysloc2, klsymm)
        end
    end

    # symmetric keys already in the same locations
    if leftkeysloc1 == leftkeysloc2
        return km2
    end

    if length(leftkeysloc1) != length(leftkeysloc2)
        error("Keymaps should have the same number of symmetric keys things will get complicated if not.")
    end

    order1 = sortperm(keys1)
    order2 = sortperm(keys2)
    leftkeysloc1 = leftkeysloc1[order1]
    rightkeysloc1 = rightkeysloc1[order1]
    leftkeysloc2 = leftkeysloc2[order2]
    rightkeysloc2 = rightkeysloc2[order2]
    
    for i in eachindex(leftkeysloc1)
        key1 = keys1[i]
        key2 = keys2[i]
        # if key1 != key2
        #     error("Ordering of symmetric keys messed up, or there are different symmetric keys.")
        # end
        leftkeyloc1 = leftkeysloc1[i]
        rightkeyloc1 = rightkeysloc1[i]
        leftkeyloc2 = leftkeysloc2[i]
        rightkeyloc2 = rightkeysloc2[i]

        swapkeys!(km2, leftkeyloc1, leftkeyloc2)
        swapkeys!(km2, rightkeyloc1, rightkeyloc2)
    end

    return km2, true
end



"""
    getbasekmpermutation
km1 and km2 will have the same layer switch locations.

Yes, it technically isn't a "permutation"; it's the mapping of keys to integers that will determine the permutation of a given keymap.
"""
function getbasekmpermutation(km1::Keymap, km2::Keymap)

    keypaths1 = keypathmap(km1)
    keypaths2 = keypathmap(km2)
    
    if (keys(keypaths1) != keys(keypaths2))
        # if the only thing missing between keymaps is `nothing`, that is ok. Such a situation means one keymap has been filled.
        if symdiff(keys(keypaths1), keys(keypaths2)) != Set([nothing])
            println(km1)
            println(km2)
            println(symdiff(keys(keypaths1), keys(keypaths2)))
            error("Something went wrong, two keymaps from the same lineage should have the same set of keycodes.") 
        end
    end

    basemap = Dict{Union{Keycodeforpermutation, Int}, Union{Keycodeforpermutation, Int}}()
    keycodecounter1 = Dict{Union{Keycode, Nothing}, Int}()
    keycodecounter2 = Dict{Union{Keycode, Nothing}, Int}()
    

    for kl in specialcases(km1)
        gridind = grid2index(km1, kl)

        keycode1 = value(km1[kl])
        if keycode1 in keys(keycodecounter1)
            keycodecounter1[keycode1] += 1
        else
            keycodecounter1[keycode1] = 1
        end

        # km2 will have the same special cases, so increment them
        if keycode1 in keys(keycodecounter2)
            keycodecounter2[keycode1] += 1
        else
            keycodecounter2[keycode1] = 1
        end

        currentkeycodepair1 = (keycode1, keycodecounter1[keycode1])

        basemap[currentkeycodepair1] = gridind
        basemap[gridind] = currentkeycodepair1

    end

    currentind = 1
    for layernum in eachindex(km1)
        layer = km1[layernum]
        for rownum in eachindex(layer)
            row = layer[rownum]
            for colnum in eachindex(row)
                
                kl = KeyLocation(layernum, (rownum, colnum))
                if isspecialcase(km1, kl) continue end

                keycode1 = value(km1[kl])
                if keycode1 in keys(keycodecounter1)
                    keycodecounter1[keycode1] += 1
                else
                    keycodecounter1[keycode1] = 1
                end

                currentkeycodepair1 = (keycode1, keycodecounter1[keycode1])
                
                if !(currentkeycodepair1 in keys(basemap))
                    while currentind in keys(basemap)
                        currentind += 1
                    end
                    basemap[currentkeycodepair1] = currentind
                    basemap[currentind] = currentkeycodepair1
                    @logmsg CrossoverLogLevel "keycode1: $currentkeycodepair1 with ind $currentind"
                    @logmsg CrossoverLogLevel basemap
                    
                end

                keycode2 = value(km2[kl])
                if keycode2 in keys(keycodecounter2)
                    keycodecounter2[keycode2] += 1
                else
                    keycodecounter2[keycode2] = 1
                end
                currentkeycodepair2 = (keycode2, keycodecounter2[keycode2])

                if !(currentkeycodepair2 in keys(basemap))
                    while currentind in keys(basemap)
                        currentind += 1
                    end
                    
                    basemap[currentkeycodepair2] = currentind
                    basemap[currentind] = currentkeycodepair2
                    @logmsg CrossoverLogLevel "keycode2: $currentkeycodepair2 with ind $currentind"
                    @logmsg CrossoverLogLevel basemap
                end
            end
        end
    end

    # if length(keypaths1[_SLSH]) == 3 || length(keypaths2[_SLSH]) == 3
    #     @logmsg currentdebuglevel "$km1 \n $km2 \n $basemap"
    # end

    return basemap

end

function getkmpermutation(km::Keymap, basemap::Dict{Union{Keycodeforpermutation, Int}, Union{Keycodeforpermutation, Int}})
    permsize = Int(length(keys(basemap)) / 2)
    perm = zeros(Int, permsize)
    unused = Set(collect(1:permsize))
    keytotal = totalkeys(km)

    layerswitchperms = Tuple{Int, Int}[]

    keycodecounter = Dict{Union{Keycode, Nothing}, Int}()
    
    debugkeys = []

    # println(km)

    for kl in specialcases(km)
        gridind = grid2index(km, kl)

        currentkey = km[kl]
        keycode = value(currentkey)
        if keycode in keys(keycodecounter)
            keycodecounter[keycode] += 1
        else
            keycodecounter[keycode] = 1
        end
        currentpair = (keycode, keycodecounter[keycode])

        newi = basemap[currentpair]

        perm[gridind] = newi
        delete!(unused, newi)
        push!(debugkeys, keycode)
    end

    # @logmsg currentdebuglevel km
    # @logmsg currentdebuglevel basemap

    currentind = 0
    for layernum in eachindex(km)
        layer = km[layernum]
        for rownum in eachindex(layer)
            row = layer[rownum]
            for colnum in eachindex(row)
                currentind += 1
                kl = KeyLocation(layernum, (rownum, colnum))
                if isspecialcase(km, kl) continue end

                currentkey = row[colnum]
                keycode = value(currentkey)
                if keycode in keys(keycodecounter)
                    keycodecounter[keycode] += 1
                else
                    keycodecounter[keycode] = 1
                end

                currentpair = (keycode, keycodecounter[keycode])
                newi = basemap[currentpair]
                perm[currentind] = newi
                delete!(unused, newi)

                if keycode == _LS
                    # if first(basemap[newi]) == _LS
                    # else
                        push!(layerswitchperms, currentind == newi ? (currentind, currentind) : (currentind, newi))
                    # end
                end
            end
        end
    end
    currentind = keytotal + 1

    for i in unused
        perm[currentind] = i
        currentind += 1
    end

    return Perm(perm), layerswitchperms
end

function _applykmpermutation!(rng::AbstractRNG, km::Keymap, basemap::Dict{Union{Keycodeforpermutation, Int}, Union{Keycodeforpermutation, Int}}, p::Perm)

    currentind = 1
    parr = p.d
    for layernum in eachindex(km)
        layer = km[layernum]
        for rownum in eachindex(layer)
            row = layer[rownum]
            for colnum in eachindex(row)
                currentkl = KeyLocation(layernum, (rownum, colnum))
                currentkey = km[currentkl]
                currentvalue = value(currentkey)
                currentmov = ismoveable(currentkey)
                currentsymm = issymmetric(currentkey)
                

                currentpermval = parr[currentind]
                replacementpair = basemap[currentpermval]
                replacementval = first(replacementpair)
                if (currentvalue == _LS && replacementval != _LS) || (currentvalue != _LS && replacementval == _LS)
                    error("Problem with crossover permutation: _LS positions should not have been moved.")
                end

                km[currentkl] = Key(replacementval, currentmov, currentsymm)
                currentind += 1
            end
        end
    end
    keypaths = keypathmap(km)
 
    # # @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    # # if a necessary key gets cut off, switch it back in
    possiblenothings = KeyLocation[]
    if nothing in keys(keypaths)
        for kls in keypaths[nothing]
            if isspecialcase(km, kls[end]) continue end # could use immovable nothing keys for non-grid layouts
            push!(possiblenothings, kls[end])
        end 
    end
    possiblekeys = KeyLocation[]
    keycodecounter = Dict{Keycode, Int}()
    for keycode in filter(x -> (x !== nothing) && (x != _LS) && (length(keypaths[x]) > 1), keys(keypaths))
        for kls in keypaths[keycode][1:end] # the first occurence of a key will usually be on the base layer, so try to keep it there
            if keycode in keys(keycodecounter)
                keycodecounter[keycode] += 1
            else
                keycodecounter[keycode] = 1
            end
            if isspecialcase(km, kls[end]) continue end
            push!(possiblekeys, kls[end])
        end
    end

    if length(possiblenothings) == 0 && length(possiblekeys) == 0
        error("Keymap is somehow too full and nothing can be switched out.")
    end

    
    swappedout = Union{Keycode, Nothing}[]
    # this theoretically should not be able to fail because the only way to exceed the keymap size without duplicates is to have different sets across the two keymaps, which is not possible since there is an initial checking making sure the sets are the same
    for i in currentind:length(parr)
        @logmsg CrossoverLogLevel "nothings $possiblenothings and keys $possiblekeys"
        remainingpair = basemap[parr[i]]
        # there is another copy in the keymap
        if remainingpair[1] in keys(keypaths)
            continue
        end

        # don't care if `nothing` keys are cut off
        if remainingpair[1] === nothing
            continue
        end

        # there is not another copy of the keycode in the keymap
        @logmsg CrossoverLogLevel "remaining pair that needs to be moved back to main keymap $remainingpair"
        
        
        possibleswitch = 
            # there is at least one `nothing` in the keymap that we will switch with
            if length(possiblenothings) > 0 && nothing in keys(keypaths)
                pop!(possiblenothings)
            else
                c = 0
                keycode = value(km[possiblekeys[end]])
                while keycodecounter[keycode] <= 1
                    if c > 60
                        @logmsg CrossoverLogLevel km
                        @logmsg CrossoverLogLevel "nothings: $possiblenothings, keys: $possiblekeys"
                        error("Keymap is somehow too full and nothing can be switched out.")
                    end
                    shuffle!(rng, possiblekeys)
                    c += 1
                    keycode = value(km[possiblekeys[end]])
                end
                keycodecounter[keycode] -= 1
                pop!(possiblekeys)
            end

        switchkeyloc = possibleswitch

        @logmsg CrossoverLogLevel "switching with $(value(km[switchkeyloc]))"
                
        km[switchkeyloc] = Key(remainingpair[1])
        
        push!(swappedout, value(km[switchkeyloc]))
        
        
    end
    @logmsg CrossoverLogLevel "remaining keycodes $swappedout"

    return km
end

"""
    crossover!
The input expects km1 to have a better score than km2.
"""
function crossover!(rng::AbstractRNG, km1::Keymap, km2::Keymap; opcounts=OperationCounter())
    if km1 == km2 
        opcounts.identitycountcrossover += 1
        return km1 
    end

    _, proceed = if rand(rng) <= 0.75
        _movelayerswitchesfrom1to2!(km1, km2)
    else
        _movelayerswitchesfrom1to2!(km2, km1)
    end
    if !proceed
        opcounts.identitycountcrossover += 1
        return km1
    end
    if km1 == km2 
        opcounts.identitycountcrossover += 1
        return km1
    end
    _movesymmetrics1to2!(km1, km2)
    basemap = getbasekmpermutation(km1, km2)

    σ, layerswitchperms = getkmpermutation(km1, basemap)
    @logmsg CrossoverLogLevel "km1 $(cycles(σ)) ($(σ.d))"
    τ, _ = getkmpermutation(km2, basemap)
    @logmsg CrossoverLogLevel "km2 $(cycles(τ)) ($(τ.d))"
    @logmsg CrossoverLogLevel "km2 inv $(cycles(inv(τ))) ($(inv(τ).d))"
    permsize = length(σ.d)
    @logmsg CrossoverLogLevel "composition pre correction $(cycles(σ * inv(τ))), $((σ * inv(τ)).d)"
    @logmsg CrossoverLogLevel "layer switch reversal perms $layerswitchperms"
    @logmsg CrossoverLogLevel "\n $km1 \n vs. $km2"
    g = SymmetricGroup(permsize)
    ν = σ * inv(τ)
    νcycles = cycles(ν)
    @logmsg CrossoverLogLevel "composition $(cycles(ν)) ($(ν.d))"
    
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
    @logmsg CrossoverLogLevel "new shifted perm: $(cycles(newandshifted)) $(newandshifted.d)"
    
    _applykmpermutation!(rng, km1, basemap, newandshifted)
    opcounts.crossovercount += 1
    @logmsg CrossoverLogLevel "crossed km \n $km1"

    return km1

end
