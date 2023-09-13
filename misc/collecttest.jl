module Noshow
    export
        LetterHolder,
        _A,
        _E,
        _U

    @enum Fakeletter _A _E _U

    struct LetterHolder
        letter::Vector
    end
    letter(l::LetterHolder) = l.letter

    Base.isless(l1::LetterHolder, l2::LetterHolder) = isless(letter(l1), letter(l2))
    function Base.hash(l::LetterHolder, h::UInt) 
        return hash(letter(l), h)
    end
    function Base.:(==)(l1::LetterHolder, l2::LetterHolder)
        return hash(l1) == hash(l2)
    end
end # module

module Withshow
    export
        LetterHolder,
        _A,
        _E,
        _U

    @enum Fakeletter _A _E _U

    struct LetterHolder
        letter::Vector
    end
    letter(l::LetterHolder) = l.letter

    # comment Base.show to see different order
    Base.show(io::IO, l::LetterHolder) = print(io, letter(l))
    Base.isless(l1::LetterHolder, l2::LetterHolder) = isless(letter(l1), letter(l2))
    function Base.hash(l::LetterHolder, h::UInt) 
        return hash(letter(l), h)
    end
    function Base.:(==)(l1::LetterHolder, l2::LetterHolder)
        return hash(l1) == hash(l2)
    end
end # module

import .Noshow
import .Withshow

println("@@@ without Base.show")
d = Dict{Noshow.LetterHolder, Float32}(Noshow.LetterHolder([Noshow._A]) => 0.4, Noshow.LetterHolder([Noshow._U]) => 0.9, Noshow.LetterHolder([Noshow._E]) => 0.75)
for k in collect(keys(d))
    println(first(Noshow.letter(k)))
end
# println("@@@ with Base.show")
# d = Dict{Withshow.LetterHolder, Float32}(Withshow.LetterHolder([Withshow._A]) => 0.4, Withshow.LetterHolder([Withshow._U]) => 0.9, Withshow.LetterHolder([Withshow._E]) => 0.75)
# for k in collect(keys(d))
#     println(first(Withshow.letter(k)))
# end

module Noshowfakehash
    export
        LetterHolder,
        _A,
        _E,
        _U

    @enum Fakeletter _A _E _U
    Base.hash(f::Fakeletter, h::UInt) = hash(string(f), h)
    # Base.:(==)(f1::Fakeletter, f2::Fakeletter) = hash(f1) == hash(f2)

    struct LetterHolder
        letter::Vector
    end
    letter(l::LetterHolder) = l.letter

    Base.isless(l1::LetterHolder, l2::LetterHolder) = isless(letter(l1), letter(l2))
    function Base.hash(l::LetterHolder, h::UInt) 
        return hash(letter(l), h)
    end
    function Base.:(==)(l1::LetterHolder, l2::LetterHolder)
        return hash(l1) == hash(l2)
    end
end # module

module Withshowfakehash
    export
        LetterHolder,
        _A,
        _E,
        _U

    @enum Fakeletter _A _E _U
    Base.hash(f::Fakeletter, h::UInt) = hash(string(f), h)
    # Base.:(==)(f1::Fakeletter, f2::Fakeletter) = hash(f1) == hash(f2)

    struct LetterHolder
        letter::Vector
    end
    letter(l::LetterHolder) = l.letter

    # comment Base.show to see different order
    Base.show(io::IO, l::LetterHolder) = print(io, letter(l))
    Base.isless(l1::LetterHolder, l2::LetterHolder) = isless(letter(l1), letter(l2))
    function Base.hash(l::LetterHolder, h::UInt) 
        return hash(letter(l), h)
    end
    function Base.:(==)(l1::LetterHolder, l2::LetterHolder)
        return hash(l1) == hash(l2)
    end
end # module

import .Noshowfakehash
import .Withshowfakehash

println("@@@ without Base.show Fakeletter hash function")
d = Dict{Noshowfakehash.LetterHolder, Float32}(Noshowfakehash.LetterHolder([Noshowfakehash._A]) => 0.4, Noshowfakehash.LetterHolder([Noshowfakehash._U]) => 0.9, Noshowfakehash.LetterHolder([Noshowfakehash._E]) => 0.75)
for k in collect(keys(d))
    println(first(Noshowfakehash.letter(k)), " has type ", typeof(k))
end
println("@@@ with Base.show Fakeletter hash function")
d = Dict{Withshowfakehash.LetterHolder, Float32}(Withshowfakehash.LetterHolder([Withshowfakehash._A]) => 0.4, Withshowfakehash.LetterHolder([Withshowfakehash._U]) => 0.9, Withshowfakehash.LetterHolder([Withshowfakehash._E]) => 0.75)
for k in collect(keys(d))
    println(first(Withshowfakehash.letter(k)), " has type ", typeof(k))
end


@enum Fakeletterout _A _U _E
println("@@@ enum outside without Base.show")
d = Dict{Noshow.LetterHolder, Float32}(Noshow.LetterHolder([_A]) => 0.4, Noshow.LetterHolder([_U]) => 0.9, Noshow.LetterHolder([_E]) => 0.75)
for k in collect(keys(d))
    println(first(Noshow.letter(k)))
end
println("@@@ enum outside with Base.show")
d = Dict{Withshow.LetterHolder, Float32}(Withshow.LetterHolder([_A]) => 0.4, Withshow.LetterHolder([_U]) => 0.9, Withshow.LetterHolder([_E]) => 0.75)
for k in collect(keys(d))
    println(first(Withshow.letter(k)))
end

