export 
    AbstractKey,
    Keyvalue,
    Key,
    value,
    contenttype,
    ismoveable,
    issymmetric,

    KeyLocation,
    layernum,
    gridposition,
    rownum,
    colnum,
    getsymmetriclocation,
    KL,

    KeyLocationSequence,
    keylocationsequence



"""
    Keyvalue
`Union{Float32, Keycode, Nothing}`, i.e., any type that can be the value of a key.
"""
const Keyvalue = Union{Float32, Keycode, Nothing}
function Base.convert(::Type{Keyvalue}, i::Int) 
    # @logmsg 1000 "Automatically converting Int key value to Float32"
    return convert(Float32, i)
end

const genericundefined = "is not defined for the concrete type."

"""
AbstractKey
Represents the basic building block of a keyboard layout.
(Maybe consider rotary encoders.)
"""
abstract type AbstractKey end

"""
value(k::AbstractKey)
Returns the value of the `Key`.
"""
value(k::AbstractKey) = error("value is not defined for $(typeof(k)).")

"""
contenttype(k::AbstractKey)
Returns the type of value that the `Key` holds.
"""
contenttype(k::AbstractKey) = error("contenttype $(genericundefined)") 

"""
ismoveable(k::AbstractKey)
Returns `true` if the `Key` is allowed to be moved by the optimizer and false if the `Key` should be fixed in its position.
"""
ismoveable(k::AbstractKey) = error("ismoveable $(genericundefined)")

"""
Base.==(k1::AbstractKey, k2::AbstractKey)
Returns true if k1 and k2 are equal, i.e., if they have the same value and moveability.
"""
Base.:(==)(k1::AbstractKey, k2::AbstractKey) = error("== $(genericundefined)")

"""
Key
A type representing a key on a keyboard. `ismoveable` indicates if the key is allowed to be moved to a different location or if it should be fixed where it is (e.g., in a layout, you may want the spacebar to always be under your thumb). `issymmetric` indicates if the key should be mirrored (e.g., usually shift is mirrored)

```jldoctest
julia> k = Key(0.032, true, false);

julia> value(k) == 0.032
true

julia> contenttype(k) == Float32
true

julia> ismoveable(k)
true

julia> issymmetric(k)
false

julia> k2 = Key(0.032, true, false);

julia> k == k2
true
```
"""
struct Key <: AbstractKey
    value::Keyvalue
    ismoveable::Bool
    issymmetric::Bool
end

"""
    Key(; ismoveable=true)
Convenience constructor for empty `Key``. Returns a `Key` with a value of nothing that is moveable.
"""
Key(; ismoveable=true, issymmetric=false) = Key(nothing, ismoveable, issymmetric)
Key(v::Keyvalue, m::Bool) = Key(v, m, false)
Key(v::Int, m::Bool) = Key(v, m, false)
"""
    Key(v::Keyvalue)
Constructor. Let `Key`s be moveable by default.
"""
Key(v::Keyvalue) = Key(v, true, false)
value(k::Key) = k.value
contenttype(k::Key) = typeof(value(k))
ismoveable(k::Key) = k.ismoveable
issymmetric(k::Key) = k.issymmetric
function Base.:(==)(k1::Key, k2::Key)
    return (value(k1) == value(k2)) && (ismoveable(k1) == ismoveable(k2)) && (issymmetric(k1) == issymmetric(k2))
end
function Base.:(==)(k1::AbstractKey, k2::Keycode) 
    @error "You probably meant to compare the value of Key $k1 with Keycode $k2."
    return false
end
Base.:(==)(k1::Keycode, k2::Key) = k2 == k1
function Base.show(io::IO, k::Key)
    keystring = ""
    if value(k) === nothing
        keystring *= "__"
    else
        keystring *= string(value(k))[2:end]
    end
    if !ismoveable(k)
        keystring *= "@f"
    end
    print(io, keystring)
    # value(k) === nothing ? print(io, "__") : print(io, string(value(k))[2:end])
end
function Base.show(io::IO, vk::Vector{Key})
    outstr = ""
    for k in vk
        outstr *= lpad(k, asciikeyspacing)
    end
    if length(vk) == 0
        println(io, "empty Key vector")
    else
        println(io, outstr)
    end
end



"""
    AbstractComboHolder
Represents what keys make up a [combo](https://docs.qmk.fm/#/feature_combo?id=combos); in general English this would better be described as a chord.
"""
abstract type AbstractComboHolder end

Base.:(==)(c1::AbstractComboHolder, c2::AbstractComboHolder) = error("== not defined for AbstractComboHolders")

"""
    AbstractKeyLocation
Represents where a particular key can be found in a keymap.
"""
abstract type AbstractKeyLocation end

"""
    KeyLocation
Specifies the location of a key in a keymap, i.e., which layer and (row, col) index it can be found.
"""
@kwdef struct KeyLocation <: AbstractKeyLocation
    layernum::Int = 0
    gridposition::Tuple{Int, Int} = (0, 0)
end
KeyLocation(ln::Int, rn::Int, cn::Int) = KeyLocation(ln, (rn, cn))
# KeyLocation(layernum::Int, gridposition::Tuple{Int, Int}) = KeyLocation(layernum=layernum, gridposition=gridposition)
# KeyLocation() = KeyLocation(layernum=0, gridposition=(0, 0))
layernum(k::KeyLocation) = k.layernum
gridposition(k::KeyLocation) = k.gridposition
rownum(k::KeyLocation) = gridposition(k)[1]
colnum(k::KeyLocation) = gridposition(k)[2]
# combokeys(k::KeyLocation) = k.combokeys
function Base.:(==)(k1::KeyLocation, k2::KeyLocation)
    return (layernum(k1) == layernum(k2)) && (gridposition(k1) == gridposition(k2)) #&& (combokeys(k1) == combokeys(k2))
end
function getsymmetriclocation(k::KeyLocation, rowlen::Int)
    layer = layernum(k)
    row = rownum(k)
    col = colnum(k)
    return KeyLocation(layer, (row, rowlen-(col-1)))
end
function Base.isless(kl1::KeyLocation, kl2::KeyLocation)
    if layernum(kl1) > layernum(kl2) return false end
    if layernum(kl1) < layernum(kl2) return true end
    # kl1 and kl2 are the same layer
    if rownum(kl1) > rownum(kl2) return false end
    if rownum(kl1) < rownum(kl2) return true end
    # kl1 and kl2 are the same row
    if colnum(kl1) > colnum(kl2) return false end
    if colnum(kl1) < colnum(kl2) return true end
    return false


end
function Base.show(io::IO, kl::KeyLocation)
    print(io, "($(layernum(kl)), [$(gridposition(kl)[1]), $(gridposition(kl)[2])])")
end

const KL = KeyLocation


"""
    AbstractKeyLocationSequence
"""
abstract type AbstractKeyLocationSequence end

"""
    KeyLocationSequence
Sequence of key locations.
"""
struct KeyLocationSequence <: AbstractKeyLocationSequence
    keylocationsequence::Vector{Union{KeyLocation, Nothing}}
end
KeyLocationSequence() = KeyLocationSequence([nothing])
KeyLocationSequence(kls::Union{KeyLocation, Nothing}...) = KeyLocationSequence(collect(kls))
"""
    KeyLocationSequence(ln::Int, gp::Tuple{Int, Int})
Create a `KeyLocationSequence` out of the args for a `KeyLocation`.
"""
KeyLocationSequence(ln::Int, gp::Tuple{Int, Int}) = KeyLocationSequence(KeyLocation(ln, gp))
keylocationsequence(kls::KeyLocationSequence) = kls.keylocationsequence
Base.isnothing(kls::KeyLocationSequence) = kls == KeyLocationSequence()
@forward KeyLocationSequence.keylocationsequence Base.iterate, Base.getindex, Base.length, Base.eachindex, Base.lastindex, Base.view
Base.append!(vec1::KeyLocationSequence, vec2::KeyLocationSequence) = KeyLocationSequence(append!(keylocationsequence(vec1), keylocationsequence(vec2)))
# Base.length(kls::KeyLocationSequence) = length(keylocationsequence(kls))
# Base.getindex(kls::KeyLocationSequence, i::Int) = keylocationsequence(kls)[i]
# Base.eachindex(kls::KeyLocationSequence) = Base.OneTo(length(kls))
# Base.lastindex(kls::KeyLocationSequence) = length(kls)
Base.:(==)(kls1::KeyLocationSequence, kls2::KeyLocationSequence) = keylocationsequence(kls1) == keylocationsequence(kls2)
Base.push!(kls::KeyLocationSequence, k::Union{KeyLocation, Nothing}) = KeyLocationSequence(push!(keylocationsequence(kls), k))
Base.vcat(kls::KeyLocationSequence, k::Union{KeyLocation, Nothing}) = KeyLocationSequence(vcat(keylocationsequence(kls), k))
Base.vcat(kls1::KeyLocationSequence, kls2::KeyLocationSequence) = KeyLocationSequence(vcat(keylocationsequence(kls1), keylocationsequence(kls2)))
Base.vcat(kls::KeyLocationSequence...) = KeyLocationSequence(reduce(vcat, keylocationsequence.(kls)))
Base.vcat(klsvec::Vector{KeyLocationSequence}) = KeyLocationSequence(reduce(vcat, klsvec))


function Base.show(io::IO, kls::KeyLocationSequence)
    print(io, join(kls, " → "))
end
function Base.show(io::IO, klsvec::Vector{KeyLocationSequence})
    print(io, "[", join(klsvec, "; "), "]")
end

# Base.iterate(kls::KeyLocationSequence) = iterate(keylocationsequence(kls))
# Base.iterate(kls::KeyLocationSequence, state) = iterate(keylocationsequence(kls), state)

