module Keyboard

using Random
import Random: default_rng
import Unitful: Quantity, unit
using Logging
using OrderedCollections
using DataStructures
using AdvancedLayoutCalculator.AlcUtils
const asciikeyspacing = 8

include("key.jl")
include("layer.jl")
include("layerswitchmap.jl")
export
    AbstractProtoKeymap,
    ProtoKeymap,
    layers,
    baselayer,
    numlayers,
    findsequencetolocation,
    genkeypathmap,
    AbstractKeymap,
    EmptyEffortLayer,
    EmptyFMLayer,
    Keymap,
    layerswitchmap,
    effortlayer,
    fingermaplayer,
    keypathmap,
    specialcases,
    swapkeys!,
    replacekey!,
    cantype,
    canreplacekeytypeability,
    genrandomloc,
    immovablekeylocations,
    genrandomsymmetriclocs,
    gen4x12keymap,
    gen5x6keymap,
    gen5x7keymap,
    genrandomkeymap

"""
    AbstractProtoKeymap
Represents a collection of layers stack on top of each other.
"""
abstract type AbstractProtoKeymap end

"""
    layers(k::AbstractProtoKeymap)
Returns a vector of the layers of the keymap.
"""
layers(k::AbstractProtoKeymap) = error("layers $(genericundefined)")

"""
    baselayer(k::AbstractProtoKeymap)
Returns the base layer of the keymap, i.e., the layer in index 1.
"""
baselayer(k::AbstractProtoKeymap) = error("baselayer $(genericundefined)")

"""
    numlayers(k::AbstractProtoKeymap)
Returns the number of layers in the keymap.
"""
numlayers(k::AbstractProtoKeymap) = error("numlayers $(genericundefined)")

"""
    numelements(k::AbstractProtoKeymap)
Returns the number of elements (keys) in the keymap.
"""
numelements(k::AbstractProtoKeymap) = error("numelements $(genericundefined)")

"""
    Base.:(==)(k1::AbstractProtoKeymap, k2::AbstractProtoKeymap)
Returns true if `k1` and `k2` have the same number of layers and if corresponding layers are identical.
"""
Base.:(==)(k1::AbstractProtoKeymap, k2::AbstractProtoKeymap) = error("== $(genericundefined)")


"""
    ProtoKeymap
Concrete type for holding a stack of layers.
"""
struct ProtoKeymap{L <: AbstractProtoLayer} <: AbstractProtoKeymap
    layers::Vector{L}
    function ProtoKeymap(vl::Vector{L}) where {L <: AbstractProtoLayer}
        if length(unique(dimensionsgran.(vl))) != 1
            error("Every layer in a keymap must have the same shape.")
        end
        return new{L}(vl)
    end
end
"""
    ProtoKeymap(ls::L...) where {L <: AbstractProtoLayer}
ProtoKeymap constructor that sluprs layers.
"""
ProtoKeymap(layers::L...) where {L <: AbstractProtoLayer} = ProtoKeymap(collect(layers))
"""
    ProtoKeymap(ls::Vector{Vector{L}}...)
ProtoKeymap constructor that slurps `Vector{Vector{L}}`s.
"""
ProtoKeymap(layers::Vector{Vector{L}}...) where {L} = ProtoKeymap(collect(ProtoLayer.(layers)))
layers(k::ProtoKeymap) = k.layers
baselayer(k::ProtoKeymap) = k[1]
numlayers(k::ProtoKeymap) = length(layers(k))
numelements(k::ProtoKeymap) = numlayers(k) * numelements(baselayer(k))
totalkeys(k::ProtoKeymap) = numelements(k)
Base.getindex(k::ProtoKeymap, i::Int) = layers(k)[i]
Base.getindex(k::ProtoKeymap, i1::Int, i2::Int, i3::Int, I::Int...) = k[i1][i2][i3]
"""
    Base.getindex(k::ProtoKeymap, kl::KeyLocation)
Index keymap using a [`KeyLocation`](@ref).
"""
Base.getindex(k::ProtoKeymap, kl::KeyLocation) = k[layernum(kl)][kl]
function Base.setindex!(l::ProtoKeymap{L}, v::L, i1::Int, i2::Int, I::Int...) where {L} 
    # @warn "You probably don't want to overwrite an entire layer." maxlog=1
    l[i1] = v
end
Base.setindex!(l::ProtoKeymap{L}, v::eltype(L), i1::Int, i2::Int, i3::Int, I::Int...) where {L} = l[i1][i2][i3] = v
Base.setindex!(l::ProtoKeymap{L}, v::eltype(L), kl::KeyLocation) where {L} = l[layernum(kl)][kl] = v
Base.eachindex(k::ProtoKeymap) = Base.OneTo(numlayers(k))
function Base.:(==)(k1::ProtoKeymap, k2::ProtoKeymap)
    if numlayers(k1) != numlayers(k2) return false end
    for i in eachindex(k1)
        l1 = k1[i]
        l2 = k2[i]
        if l1 != l2 return false end
    end
    return true
end

function grid2index(km::AbstractProtoKeymap, layernum::Int, (rownum, colnum)::Tuple{Int, Int})
    bl = baselayer(km)
    layerkeycount = totalkeys(bl)
    indexinlayer = grid2index(bl, (rownum, colnum))
    return (layernum - 1) * layerkeycount + indexinlayer
end

function grid2index(km::AbstractProtoKeymap, kl::KeyLocation)
    return grid2index(km, layernum(kl), gridposition(kl))
end

function index2grid(km::AbstractProtoKeymap, i::Int)
    bl = baselayer(km)
    layerkeycount = totalkeys(bl)
    layernum = Int(floor((i - 1) / layerkeycount)) + 1
    convertedi = i - layerkeycount * (layernum - 1)
    gridpos = index2grid(bl, convertedi)
    return KeyLocation(layernum, gridpos)

end


_iskeyspecialcase(k::Key) = !ismoveable(k) || issymmetric(k) || value(k) == _LS


"""
    AbstractKeymap
Represents a full keyboard layout, i.e., a collection of layers stacked on top of each other, how to access each layer, and how to access each key.
"""
abstract type AbstractKeymap <: AbstractProtoKeymap end

# todo: need to sort out types with genkeypathmap since the entities within should only be keys
"""
"""
function genkeypathmap(pk::AbstractProtoKeymap, ls::LayerSwitchmap) # where {L <: AbstractKbdLayer}
    d = Dict{Keyvalue, Vector{KeyLocationSequence}}()
    specialcases = SortedSet{KeyLocation}()
    for layernum in eachindex(pk)
        layer = pk[layernum]
        for rownum in eachindex(layer)
            for colnum in eachindex(layer[rownum])
                keyvalue = value(layer[rownum, colnum])
                loc = KeyLocation(layernum, (rownum, colnum))
                # todo: checking for immovable/symmetry should be hooked in with `isspecialcase` from layout calc
                if !ismoveable(pk[loc]) || issymmetric(pk[loc]) || value(pk[loc]) == _LS
                    push!(specialcases, loc)
                end
                keylocseq = findsequencetolocation(ls, loc)
                if keyvalue in keys(d)
                    push!(d[keyvalue], keylocseq)
                else
                    d[keyvalue] = [keylocseq]
                end
            end
        end
    end
    return d, specialcases
end

const EmptyEffortLayer = EffortLayer(Vector{Vector{Float32}}())
const EmptyFMLayer = FingerMapLayer(Vector{Vector{Tuple{Hand, Finger}}}())
# todo: check that if two keys are symmetric, they have the same moveability
"""
    Keymap{L}
Concrete type for `Keymap` with `Layer`s of type `L <: AbstractKbdLayer`. `keypathmap` records the sequence of positions to reach each key.
"""
mutable struct Keymap{L <: AbstractKbdLayer, F <: AbstractFloat} <: AbstractKeymap
    layers::ProtoKeymap{L}
    layerswitchmap::LayerSwitchmap
    effortlayer::EffortLayer{F}
    fingermaplayer::FingerMapLayer
    keypathmap::Dict{Keyvalue, Vector{KeyLocationSequence}}
    specialcases::SortedSet{KeyLocation}
    function Keymap(vl::ProtoKeymap{L}, lsl::LayerSwitchmap, el::EffortLayer{F}, fl::FingerMapLayer) where {L <: AbstractKbdLayer, F <: AbstractFloat}
        # todo: check that layer switch locations actually exist in the ProtoKeymap
        return new{L, F}(vl, lsl, el, fl, genkeypathmap(vl, lsl)...)
    end
end
# todo: allow layerswitchmap to just be a vector of keylocations
# todo: if there is only a single layer, allow construction without a layerswitchmap
function Keymap(layers::Vector{L}, layerswitches::LayerSwitchmap) where {L <: AbstractKbdLayer} 
    return Keymap(ProtoKeymap(layers), layerswitches, EmptyEffortLayer, EmptyFMLayer)
end
function Keymap(layers::Vector{L}, layerswitches::LayerSwitchmap, effortlayer::EffortLayer{F}) where {L <: AbstractKbdLayer, F <: AbstractFloat} 
    return Keymap(ProtoKeymap(layers), layerswitches, effortlayer, EmptyFMLayer)
end
function Keymap(layers::Vector{L}, layerswitches::LayerSwitchmap, effortlayer::EffortLayer{F}, fingermaplayer::FingerMapLayer) where {L <: AbstractKbdLayer, F <: AbstractFloat} 
    return Keymap(ProtoKeymap(layers), layerswitches, effortlayer, fingermaplayer)
end
function Keymap(layers::Vector{L}; layerswitches::LayerSwitchmap, effortlayer::EffortLayer=EmptyEffortLayer, fingermaplayer::FingerMapLayer=EmptyFMLayer) where {L <: AbstractKbdLayer} 
    return Keymap(ProtoKeymap(layers), layerswitches, effortlayer, fingermaplayer)
end
function Keymap(layers::L...; layerswitches::LayerSwitchmap, effortlayer::EffortLayer=EmptyEffortLayer, fingermaplayer::FingerMapLayer=EmptyFMLayer) where {L <: AbstractKbdLayer}
    return Keymap(ProtoKeymap(collect(layers)), layerswitches, effortlayer, fingermaplayer)
end
function Keymap(layers::Vector{Vector{Key}}...; layerswitches::LayerSwitchmap, effortlayer::EffortLayer=EmptyEffortLayer, fingermaplayer::FingerMapLayer=EmptyFMLayer) 
    return Keymap(ProtoKeymap(collect(Layer.(layers))), layerswitches, effortlayer, fingermaplayer)
end

@forward Keymap.layers layers, baselayer, numlayers, numelements, totalkeys, Base.getindex, Base.eachindex
@forward Keymap.layerswitchlocations getpositiontoenterlayer
layerswitchmap(k::Keymap) = k.layerswitchmap
effortlayer(k::Keymap) = k.effortlayer
fingermaplayer(k::Keymap) = k.fingermaplayer
keypathmap(k::Keymap) = k.keypathmap
specialcases(k::Keymap) = k.specialcases
haskeyvalue(k::Keymap, kc::Keyvalue) = kc in keys(keypathmap(k))
function getsymmetriclocation(kl::KeyLocation, km::Keymap)
    l = layernum(kl)
    r = rownum(kl)
    rowlen = length(baselayer(km)[r])
    return getsymmetriclocation(kl, rowlen)
end
Base.getindex(k::Keymap, kc::Keyvalue) = keypathmap(k)[kc]
function Base.setindex!(k::Keymap{L}, newkey::eltype(L), kl::KeyLocation) where {L <: AbstractKbdLayer}
    # println("replacing at ", kl, " with ", newkey)
    newkeyvalue = value(newkey)
    currentkey = k[kl]
    currentkeyvalue = value(currentkey)
    currentkeypaths = k[currentkeyvalue]
    currentpath = KeyLocationSequence()
    currentind = 0
    for (i, path) in enumerate(currentkeypaths)
        # if the end of the path is the key location we are trying to overwrite, remember this path, remove it from the current keyvalue and add it to v
        if path[end] == kl
            currentpath = path
            currentind = i
            break
        end
    end
    deleteat!(currentkeypaths, currentind)
    if haskeyvalue(k, newkeyvalue)
        push!(keypathmap(k)[newkeyvalue], currentpath)
    else
        keypathmap(k)[newkeyvalue] = [currentpath]
    end
    # may want to keep keys with empty values to keep track of what needs to be typeable
    if length(k[currentkeyvalue]) == 0
        delete!(keypathmap(k), currentkeyvalue)
    end

    if _iskeyspecialcase(currentkey)
        delete!(specialcases(k), kl)
    end
    if _iskeyspecialcase(newkey)
        push!(specialcases(k), kl)
    end

    k[layernum(kl)][kl] = newkey
end
# Base.setindex!(k::Keymap, newkey::Keyvalue, kl::KeyLocation) = k[kl] = Key(newkey)
Base.setindex!(k::Keymap{L}, newkey::eltype(L), i1::Int, i2::Int, i3::Int, I::Int...) where {L} = k[KeyLocation(i1, (i2, i3))] = newkey
function Base.:(==)(k1::Keymap, k2::Keymap)
    if numlayers(k1) != numlayers(k2) return false end
    return layers(k1) == layers(k2) && layerswitchmap(k1) == layerswitchmap(k2) && keypathmap(k1) == keypathmap(k2) && effortlayer(k1) == effortlayer(k2) && fingermaplayer(k1) == fingermaplayer(k2)
    return true
end

function Base.show(io::IO, km::Keymap)
    for lind in eachindex(km)
        layer = km[lind]
        # println(io, "L$lind", repeat("-", asciikeyspacing * dimensions(layer)[2]))
        println(io, repeat("-", asciikeyspacing))
        println(io, layer)
        # todo: other layout information 
    end
    println(io, locations(layerswitchmap(km)))
    println(io)
    println(io, effortlayer(km))
    println(io, fingermaplayer(km))
    # println(io, keypathmap(km))
end

function cantype(km::Keymap, keypool::S) where {S <: AbstractSet}
    return issubset(keypool, keys(keypathmap(km)))
end

"""
    canreplacekeytypeability
Checks if a key can be replaced, i.e., if the key is removed that there will still be at least one path to it. Ignores key moveability.
"""
function canreplacekeytypeability(km::Keymap, kc::Union{Keycode, Nothing}; minpaths=1) # todo: switch args order?
    return kc === nothing || length(keypathmap(km)[kc]) > minpaths
end

function swapkeys!(km::Keymap, l1::KeyLocation, l2::KeyLocation)
    k1 = km[l1]
    k2 = km[l2]
    km[l1] = k2
    km[l2] = k1
end

function replacekey!(km::Keymap, k::Key, l::KeyLocation)
    km[l] = k
end


function _genrandomloc(rng::AbstractRNG, k::Keymap; layernum=nothing)
    randlayernum = layernum === nothing ? rand(rng, 1:numlayers(k)) : layernum
    randlayer = k[randlayernum]
    randrownum = rand(rng, 1:numrows(randlayer))
    randrow = randlayer[randrownum]
    randcolnum = rand(rng, 1:length(randrow))
    kl = KeyLocation(randlayernum, (randrownum, randcolnum))
    return kl
end
"""
    genrandomloc(k::Keymap)
Will not generate a location that is immovable. Optional `layernum` allows one to specify which layer the random position should be selected from.
"""
function genrandomloc(rng::AbstractRNG, k::Keymap; layernum=nothing)
    # optional: determine which positions are allowed and randomly choose from those (to generate from a to b but exclude c, generate a to b-1 and add 1 if >= c)
    c = 0
    randloc = _genrandomloc(rng, k; layernum=layernum)
    while !ismoveable(k[randloc])
        if c >= 60
            # @warn "Unable to find a random moveable key location even after 60 iterations, returing nothing instead of a location." maxlog=1
            return nothing
        end
        randloc = _genrandomloc(rng, k; layernum=layernum)
        c += 1
    end
    @logmsg CounterLogLevel "reroll counter $c"
    return randloc
end
genrandomloc(args...; kwargs...) = genrandomloc(default_rng(), args...; kwargs...)

function immovablekeylocations(km::Keymap)
    immovables = Set{KeyLocation}()
    for layernum in eachindex(km)
        layer = km[layernum]
        for rownum in eachindex(layer)
            row = layer[rownum]
            for colnum in eachindex(row)
                kl = KeyLocation(layernum, (rownum, colnum))
                if !ismoveable(km[kl])
                    push!(immovables, kl)
                end
            end
        end
    end
    return immovables
end

"""
    genrandomkeymap(template::AbstractKeymap, validkeys::Vector{Keycode}; seed = rand(Int))
Generates random keymap from a `template` keymap using `validkeys`. Non-`nothing` and non-moveable `Key`s from `template` will remain in their positions. Currently, you are responsible for ensuring layer switch positions are properly placed in the template.

Returns `randomkeymap, remainingkeys` where `randomkeymap` is the random keymap and `remainingkeys` holds any keys not used.
"""
function genrandomkeymap(rng::AbstractRNG, template::AbstractKeymap, validkeys::Vector{Keycode}; symmetricshift=true)
    layers = Vector{Layer{Key}}()
    validkeys2 = deepcopy(validkeys)
    filter!(x -> !(x in keys(keypathmap(template))), validkeys2)
    for i in eachindex(template)
        layer = template[i]
        # if length(validkeys2) == 0
        #     append!(validkeys2, deepcopy(validkeys))
        # end
        rlayer, validkeys2 = genrandomlayer(rng, layer, validkeys2; symmetricshift=symmetricshift)
        push!(layers, rlayer)
    end
    # remainingcount = length(validkeys2)
    # if remainingcount > 0
    #     error("There are $remainingcount remaining keys that have not been placed into the keymap; you won't be able to type everything you need.")
    # end
    return Keymap(layers, layerswitchmap(template), effortlayer(template), fingermaplayer(template)), validkeys2
end
genrandomkeymap(args...; kwargs...) = genrandomkeymap(default_rng(), args...; kwargs...)

include("keymaptemplates.jl")



end # module