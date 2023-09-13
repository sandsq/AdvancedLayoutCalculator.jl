export
    LayerSwitchmap,
    switchmap,
    locations,
    types,
    getpositiontoenterlayer

"""
    AbstractLayerSwitch
Represents layer switching.
"""
abstract type AbstractLayerSwitchmap end

"""
    findsequencetolocation(lsl::Vector{KeyLocation}, targetlocation::KeyLocation)
Find the sequence of keys needed to press given `targetlocation`. Includes `targetlocation` as the last "key press".
"""
function findsequencetolocation(lsl::Vector{KeyLocation}, targetlocation::KeyLocation)
    sequence = KeyLocation[targetlocation]
    baselayer = 1
    counter = 0
    targetlayer = layernum(targetlocation)
    while targetlayer > baselayer
        locationtolayer = lsl[targetlayer]
        pushfirst!(sequence, locationtolayer)
        targetlayer = layernum(locationtolayer)
        if counter > 32
            # @warn "There is a problem with your layer access, stopping after 32 hops and returning KeyLocationSequence()." maxlog=1
            return KeyLocationSequence()
        end
        counter += 1
    end
    return KeyLocationSequence(sequence)
end


"""
    LayerSwitch
Should have the same number of layers as the corresponding `Keymap`. Index i contains the location of the key needed to enter layer i, as well as the [type of layer switching it is](https://docs.qmk.fm/#/feature_layers?id=switching-and-toggling-layers). Initial implementation should follow the guidelines in the "Beginners" section. Importantly, that there is only one access point for a given layer
"""
struct LayerSwitchmap <: AbstractLayerSwitchmap
    locations::Vector{KeyLocation} # index i holds the location of the key that switches to layer i
    switchmap::Vector{KeyLocationSequence} # index i holds the sequences of keys needed to switch to layer i
    types::Vector{String}

    LayerSwitchmap(kl::Vector{KeyLocation}, kls::Vector{KeyLocationSequence}, lst::Vector{String}) = new(kl, kls, lst)
    function LayerSwitchmap(kl::Vector{KeyLocation}, lst::Vector{String})
        if length(kl) != length(lst)
            error("Mismatch between number of layers and number of corresponing layer types.")
        end
        layerswitchlocations = KeyLocation[]
        for i in 2:length(kl)
            k = kl[i]
            push!(layerswitchlocations, k)
        end
        @logmsg KeymapLogLevel "remaking LayerSwitchmap, locations are $layerswitchlocations"
        if length(unique(layerswitchlocations)) != length(layerswitchlocations)
            error("Multiple layer switches use the same key position so you might get stuck in a layer. This is an error for now.")
        end

        sequences = KeyLocationSequence[KeyLocationSequence()]
        # start from 2 since layer 1 is the base layer, which is always on by default
        if length(kl) == 1
            return new(kl, sequences, lst)
        end
        for i in 2:length(kl)
            keylocation = kl[i]
            if keylocation == KeyLocation()
                error("Not possible to reach every layer.")
            end
            if layernum(keylocation) > i
                error("It is not recommended to access a lower layer from a higher one. This is an error for now.")
            end
            s = findsequencetolocation(kl, keylocation)
            push!(sequences, s)
        end
        return new(kl, sequences, lst)
    end
end
function LayerSwitchmap(kl::Vector{KeyLocation})
    lst = fill("hold", length(kl))
    return LayerSwitchmap(kl, lst)
end
LayerSwitchmap(lsl::KeyLocationSequence...) = LayerSwitchmap(collect(lsl))
LayerSwitchmap(lsl::KeyLocation...) = LayerSwitchmap(collect(lsl))
LayerSwitchmap() = LayerSwitchmap(KeyLocation())
locations(lsl::LayerSwitchmap) = lsl.locations
switchmap(lsl::LayerSwitchmap) = lsl.switchmap
types(lsl::LayerSwitchmap) = lsl.types
numlayers(lsl::LayerSwitchmap) = length(switchmap(lsl))
"""
    Base.getindex(ls::LayerSwitches, i::Int) 
Returns the sequence necessary to reach layer i (as well as the type of layer switch it is)
"""
getpositiontoenterlayer(lsl::LayerSwitchmap, i::Int) = locations(lsl)[i]
# function Base.getindex(lsl::LayerSwitchmap, i::Int) 
#     return (switchmap(lsl)[i], types(lsl)[i])
# end
function Base.getindex(lsl::LayerSwitchmap, kl::KeyLocation)
    ln = layernum(kl)
    return switchmap(lsl)[ln]
end
@forward LayerSwitchmap.locations Base.eachindex
# Base.eachindex(lsl::LayerSwitchmap) = Base.OneTo(numlayers(lsl))
function Base.:(==)(ls1::LayerSwitchmap, ls2::LayerSwitchmap)
    return locations(ls1) == locations(ls2) && switchmap(ls1) == switchmap(ls2) && types(ls1) == types(ls2)
end

function findsequencetolocation(lsl::LayerSwitchmap, targetlocation::KeyLocation)
    return layernum(targetlocation) == 1 ? KeyLocationSequence(targetlocation) : vcat(lsl[targetlocation], targetlocation)
end