export
    grid2index,
    index2grid,
    AbstractProtoLayer,
    ProtoLayer,
    layout,
    numrows,
    dimensions,
    dimensionsgran,
    totalkeys,
    numelements,
    setlayerindex!,
    AbstractKbdLayer,
    Layer,
    keypositions,
    @layer_str,
    @layers_str,
    @elayer_str,
    @flayer_str,
    gentemplatelayer,
    gen4x12effortlayer,
    genrandomlayer,
    EffortLayer,
    FingerMapLayer,
    gen4x12fingermaplayer

function grid2index(numrows::Int, numcols::Int, gridpos::Tuple{Int, Int})
    # @warn "For converting a grid position to an index, we are currently assuming keymaps are rectangular." maxlog=1
    return (gridpos[1] - 1) * numcols + gridpos[2]
end

function index2grid(numrows::Int, numcols::Int, i::Int)
    # @warn "For converting an index to a grid position, we are currently assuming keymaps are rectangular." maxlog=1
    r = Int(floor((i - 1) / numcols)) + 1
    # c = i - (r - 1) * numcols
    c = (i - 1) % numcols + 1
    return (r, c)
end

"""
    AbstractProtoLayer
Represents anything that has the shape of a [keyboard layer](https://docs.qmk.fm/#/keymap?id=keymap-overview). For example, an arrangement of keycodes is what we might traditionally think of as a keyboard layer. However, we could have a corresponding layer that stores the physical positions of each such key, or a layer that stores some keycap design for each key, etc.
"""
abstract type AbstractProtoLayer end

"""
    layout(l::AbstractProtoLayer)
Returns the layout information for `l`.
"""
layout(l::AbstractProtoLayer) = error("layout $(genericundefined)")

"""
    numrows(l::AbstractProtoLayer)
Returns the number of rows the layer has.
"""
numrows(l::AbstractProtoLayer) = error("numrows $(genericundefined)")

"""
    dimensions(l::AbstractProtoLayer)
Returns `(number of rows, number of columns in the longest row)`.
"""
dimensions(l::AbstractProtoLayer) = error("dimensions $(genericundefined)")

"""
    dimensionsgran(l::AbstractProtoLayer)
Returns a vector with `length = number of rows` where each element is the number of columns in the corresponding row. "Dimensions granular".
"""
dimensionsgran(l::AbstractProtoLayer) = error("dimensionsgran $(genericundefined)")

"""
    numelements(l::AbstractProtoLayer)
Returns the number of elements in the layer.
"""
numelements(l::AbstractProtoLayer) = error("numelements $(genericundefined)")

"""
    Base.eltype(l::AbstractProtoLayer)
Returns the type of element contained in the layer.
"""
Base.eltype(l::AbstractProtoLayer) = error("eltype $(genericundefined)")

"""
    Base.==(l1::AbstractProtoLayer, l2::AbstractProtoLayer)
Returns true if layers are identical, i.e., if they both have the same granular dimensions and the values and sizes of each key are equal.
"""
Base.:(==)(l1::AbstractProtoLayer, l2::AbstractProtoLayer) = layout(l1) == layout(l2)


"""
    ProtoLayer
Concrete type representing anything that has the shape of a keyboard layer. `L` stores the type of the element in the layer. Can index like a matrix, e.g., `pl[i, j]` returns the element in the ith row and jth column. 

```jldoctest
julia> xvecvec = [[1, 2], [3, 4, 5], [6]];

julia> pl = ProtoLayer(xvecvec);

julia> layout(pl) == xvecvec
true

julia> numrows(pl) == 3
true

julia> dimensions(pl) == (3, 3)
true

julia> dimensionsgran(pl) == [2, 3, 1]
true

julia> numelements(pl) == 6
true

julia> eltype(pl) == Int
true

julia> pl[3, 1] == 6
true
```
"""
struct ProtoLayer{L} <: AbstractProtoLayer
    layout::Vector{Vector{L}}
    function ProtoLayer(layout::Vector{Vector{L}}) where {L} 
        # @warn "Making a deepcopy of the input Vector of Vectors so that the original Vec of Vecs can be reused." maxlog=1
        new{L}(deepcopy(layout))
    end
end
@forward ProtoLayer.layout Base.isempty
layout(l::ProtoLayer) = l.layout
numrows(l::ProtoLayer) = length(layout(l))
dimensions(l::ProtoLayer) = (numrows(l), maximum(length.(layout(l))))
dimensionsgran(l::ProtoLayer) = length.(layout(l))
numelements(l::ProtoLayer) = sum(dimensionsgran(l))
totalkeys(l::ProtoLayer) = numelements(l)
Base.eltype(l::ProtoLayer{L}) where {L} = L
Base.getindex(l::ProtoLayer, i) = layout(l)[i]
Base.getindex(l::ProtoLayer, i1::Int, i2::Int, I::Int...) = l[i1][i2]
"""
    Base.getindex(l::ProtoLayer, kl::KeyLocation)
Index a layer using a [`KeyLocation`](@ref); ignores the layernum field.
"""
Base.getindex(l::ProtoLayer, kl::KeyLocation) = l[gridposition(kl)...]
function Base.setindex!(l::ProtoLayer{L}, v::L, i1::Int, i2::Int, I::Int...) where {L}
    error("Using $(l)[$i1, $i2] to set a key in a layer is currently not allowed due to complications with setindex! on Keymaps, use setlayerindex!(layer, value, i1, i2, I...) instead.")
    # l[i1][i2] = v
end
setlayerindex!(l::ProtoLayer{L}, v::L, i1::Int, i2::Int, I::Int...) where {L} = layout(l)[i1][i2] = v
Base.setindex!(l::ProtoLayer{L}, v::L, kl::KeyLocation) where {L} = setlayerindex!(l, v, gridposition(kl)...)
Base.eachindex(l::ProtoLayer) = Base.OneTo(numrows(l))
grid2index(l::AbstractProtoLayer, gridpos::Tuple{Int, Int}) = grid2index(dimensions(l)..., gridpos)
index2grid(l::AbstractProtoLayer, i::Int) = index2grid(dimensions(l)..., i)


"""
    AbstractKbdLayer
Represents a keyboard layer.
"""
abstract type AbstractKbdLayer <: AbstractProtoLayer end

# todo: should any Layer be able to contain any subtype of AbstractKey?

"""
    Layer
Concrete type representing a keyboard layer. Uses `ProtoLayer` with element type `Key`. See also [`ProtoLayer`](@ref)
"""
struct Layer{L <: AbstractKey} <: AbstractKbdLayer
    layout::ProtoLayer{L}
end
"""
    Layer(l::Vector{Vector{Key}})
Construct a keyboard `Layer` from a Vector of Vector arrangement of `Key`s.
"""
function Layer(l::Vector{Vector{L}}) where {L <: AbstractKey} 
    return Layer(ProtoLayer(l))
end
Layer{L}(l::Vector{Vector{L}}) where {L <: AbstractKey} = Layer(l)
@forward Layer.layout layout, numrows, dimensions, dimensionsgran, numelements, totalkeys, Base.eltype, Base.getindex, Base.setindex!, setlayerindex!, Base.eachindex

function Base.show(io::IO, l::Layer{L}) where {L <: AbstractKey}
    for rowi in eachindex(l)
        row = l[rowi]
        print(io, row)
    end
end

function gentemplatelayer(rowsizes::Vector{Int})
    layer = Vector{Vector{Key}}()
    for rowsize in rowsizes
        row = fill(Key(), rowsize)
        push!(layer, row)
    end
    return Layer(layer)
end
function gentemplatelayer(numrows::Int, numcols::Int)
    rowsizes = fill(numcols, numrows)
    return gentemplatelayer(rowsizes)
end

macro layer_str(s)
    rows = split(s, "\n")
    layer = Vector{Vector{Key}}()
    for row in rows
        if length(row) == 0 continue end
        keyrow = Key[]
        cols = split(row)
        if length(cols) == 0 continue end
        for col in cols
            # if length(col) == 0 continue end
            vs = split(col, "@")
            # println(vs)
            v = vs[1] == "__" ? nothing : eval(Meta.parse("_$(vs[1])"))
            mov = true
            if length(vs) > 1 
                mov = vs[2] == "f" || !Meta.parse(vs[2]) ? false : true
            end
            push!(keyrow, Key(v, mov))
        end
        push!(layer, keyrow)
    end
    return Layer(layer)
end

macro layers_str(s)
    kmholder = Vector{Layer{Key}}()
    layers = split(s, repeat("-", asciikeyspacing))
    for layerstr in layers
        if layerstr == "" continue end
        layer = @eval @layer_str $layerstr #esc("\"$(escape_string(layerstr))\""))
        push!(kmholder, layer)
    end
    return kmholder
end

macro elayer_str(s)
    rows = split(s, "\n")
    layer = Vector{Vector{Float32}}()
    for row in rows
        if length(row) == 0 continue end
        keyrow = Float32[]
        cols = split(row)
        if length(cols) == 0 continue end
        for col in cols
            colval = Meta.parse(col)
            if !(typeof(colval) <: Real)
                error("Type of $(typeof(colval)) not compatible with EffortLayer.")
            end
            push!(keyrow, colval)
        end
        push!(layer, keyrow)
    end
    return EffortLayer(layer)
end

macro flayer_str(s)
    rows = split(s, "\n")
    layer = Vector{Vector{Tuple{Hand, Finger}}}()
    for row in rows
        if length(row) == 0 continue end
        keyrow = Tuple{Hand, Finger}[]
        cols = split(row)
        if length(cols) == 0 continue end
        for col in cols
            colval = eval(Meta.parse(col))
            if typeof(colval) != Tuple{Hand, Finger}
                error("Type of $(typeof(colval)) not compatible with FingerMapLayer.")
            end
            push!(keyrow, colval)
        end
        push!(layer, keyrow)
    end
    return FingerMapLayer(layer)
end

"""
    genrandomlayer(template::L, validkeys::Vector{Keycode}; seed = rand(Int)) where {L <: AbstractKbdLayer}
Generates a random layer with `dimensionsgran(template)` containing `validkeys` using `Xoshiro(seed)` as the `rng`. Non-`nothing` and non-moveable `Key`s from `template` will remain in their positions. Note that if you intend for a pair of keys to be symmetric, they should be placed as such in the template you provide.

Returns `randomlayer, remainingkeys`, where `randomlayer` is the random layer and `remainingkeys` is a vector of whatever keys are left over after filling the `template`. Note that the input `validkeys` is not mutated.
"""
function genrandomlayer(rng::AbstractRNG, template::L, validkeys::Vector{Keycode}; symmetricshift=true) where {L <: AbstractKbdLayer}

    validkeyscopy = deepcopy(validkeys)
    shuffle!(rng, validkeyscopy)
    templatetype = eltype(template)
    nrows = numrows(template)
    randomlayer = Vector{Vector{templatetype}}(undef, nrows)
    for i in eachindex(template)
        row = template[i]
        rowlen = length(row)
        randomrow = Vector{templatetype}(undef, rowlen)
        for j in eachindex(row)
            key = template[i, j]
            keyvalue = value(key)
            keyismoveable = ismoveable(key)
            keyissymmetric = issymmetric(key)

            # if length(validkeyscopy) == 0
            #     append!(validkeyscopy, shuffle!(deepcopy(validkeys)))#[_F, _Y, _D, _U, _O, _R, _A, _N, _I, _H, _T, _E])
            # end

            if keyvalue !== nothing || !keyismoveable || keyissymmetric
                randomrow[j] = key
                continue
            elseif length(validkeyscopy) == 0
                randomrow[j] = Key()
                continue
            end
            randkey = validkeyscopy[end]
            if randkey == _SFT && symmetricshift
                mirrorind = rowlen-(j-1)
                mirrorkey = randomrow[mirrorind]
                if !ismoveable(mirrorkey) # if the location of the mirror is fixed
                    # @warn "Symmetric shift led to a conflict with a fixed key so another key got moved around; it's probably fine but you might want to double check." maxlog=1
                    pop!(validkeyscopy) # the next pop will not be _SFT anymore, as this is _SFT
                    randomrow[j] = length(validkeyscopy) == 0 ? Key() : Key(pop!(validkeyscopy)) # assign it something else
                    push!(validkeyscopy, _SFT) # put _SFT back in
                else # if the location of the mirror is allowed to be moved
                    pop!(validkeyscopy) # next pop will not be _SFT anymore
                    readd = value(randomrow[mirrorind])
                    if readd !== nothing 
                        # @warn "Symmetric shift is overriding a key that was already there; it's probably fine but you might want to check that things are ok." maxlog=1
                        push!(validkeyscopy, readd) # remove the key at the mirror location and readd it to potential random keys
                    end
                    randomrow[j] = Key(_SFT, true, true)
                    randomrow[end-(j-1)] = Key(_SFT, true, true)
                end
                
            else
                randomrow[j] = Key(pop!(validkeyscopy))
            end
        end
        randomlayer[i] = randomrow
    end
    # println("random layer\n", randomlayer)
    return L(randomlayer), validkeyscopy
end
"""
    genrandomlayer(template::Vector{Vector{Key}}, validkeys::Vector{Keycode}; seed = rand(Int), T::Type{L} = Layer)
Generates a random layer with default type `Layer` from a Vector{Vector{Key}}. Returns the same `randomlayer, remainingkeys` as [`genrandomlayer(::L, ::Vector{Keycode}) where {L <: AbstractKbdLayer}`](@ref)
"""
function genrandomlayer(rng::AbstractRNG, template::Vector{Vector{Key}}, validkeys::Vector{Keycode}; T::Type{L} = Layer, symmetricshift=true) where {L <: AbstractKbdLayer}
    return genrandomlayer(rng, T(template), validkeys; symmetricshift=symmetricshift)
end

genrandomlayer(args...; kwargs...) = genrandomlayer(default_rng(), args...; kwargs...)





struct EffortLayer{L <: AbstractFloat} <: AbstractProtoLayer
    layout::ProtoLayer{L}
end
EffortLayer(l::Vector{Vector{L}}) where {L <: AbstractFloat} = EffortLayer(ProtoLayer(l))
# Base.getindex(l::EffortLayer, kl::KeyLocation) = l[gridposition(kl)...]
@forward EffortLayer.layout layout, numrows, dimensions, dimensionsgran, numelements, totalkeys, Base.eltype, Base.getindex, Base.setindex!, setlayerindex!, Base.eachindex, Base.isempty

function Base.show(io::IO, l::EffortLayer)
    for rowi in eachindex(l)
        row = l[rowi]
        println(io, join(row, " "), "\t")
    end
end

function _scale()

end
"""
    gen4x12effortlayer
Effort layer for 4x12.
"""
function gen4x12effortlayer()
    # modifying beakl
    row1 = Float32[8,   5,   1,   1,   1,    3,      3,    1,   1,   1,   5,   8]
    row2 = Float32[7,   4,   0.5, 0.5, 0.5,  1.5,    1.5,  0.5, 0.5, 0.5, 4,   7]
    row3 = Float32[6,   3,   1.5, 2,   1,    4,      4,    1,   2,   1.5, 3,   6]
    row4 = Float32[9,   7,   6,   3,   0.75,  0.25,   0.25, 0.75, 3,   6,   7,   9]
    return EffortLayer([row1, row2, row3, row4])
end

"""
    FingerMapLayer
Should be able to specify multiple fingers for the same key (for example, you might shift your hand to hit a certain key and thus another spot would have multiple viable fingers.)
"""
struct FingerMapLayer <: AbstractProtoLayer
    layout::ProtoLayer{Tuple{Hand, Finger}}
end
FingerMapLayer(l::Vector{Vector{Tuple{Hand, Finger}}}) = FingerMapLayer(ProtoLayer(l))
# Base.getindex(l::FingerMapLayer, kl::KeyLocation) = l[gridposition(kl)...]
@forward FingerMapLayer.layout layout, numrows, dimensions, dimensionsgran, numelements, totalkeys, Base.length, Base.eltype, Base.getindex, Base.setindex!, setlayerindex!, Base.eachindex, Base.isempty

function gen4x12fingermaplayer()
    row1 = Tuple{Hand, Finger}[(left, pinkie), (left, pinkie), (left, ring), (left, middle), (left, index), (left, index), (right, index), (right, index), (right, middle), (right, ring), (right, pinkie), (right, pinkie)]
    row2 = Tuple{Hand, Finger}[(left, pinkie), (left, pinkie), (left, ring), (left, middle), (left, index), (left, index), (right, index), (right, index), (right, middle), (right, ring), (right, pinkie), (right, pinkie)]
    row3 = Tuple{Hand, Finger}[(left, pinkie), (left, pinkie), (left, ring), (left, middle), (left, index), (left, index), (right, index), (right, index), (right, middle), (right, ring), (right, pinkie), (right, pinkie)]
    row4 = Tuple{Hand, Finger}[(left, pinkie), (left, pinkie), (left, thumb), (left, thumb), (left, thumb), (left, thumb), (right, thumb), (right, thumb), (right, thumb), (right, thumb), (right, pinkie), (right, pinkie)]
    return FingerMapLayer([row1, row2, row3, row4])
end

function Base.show(io::IO, l::FingerMapLayer)
    for rowi in eachindex(l)
        row = l[rowi]
        for col in row
            print(io, "($(col[1]),$(col[2]))\t")
        end
        if rowi != numrows(l) println(io) end
    end
end