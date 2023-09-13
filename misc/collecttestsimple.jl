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

    Base.show(io::IO, l::LetterHolder) = print(io, letter(l))
    Base.isless(l1::LetterHolder, l2::LetterHolder) = isless(letter(l1), letter(l2))
    function Base.hash(l::LetterHolder, h::UInt) 
        return hash(letter(l), h)
    end
    function Base.:(==)(l1::LetterHolder, l2::LetterHolder)
        return hash(l1) == hash(l2)
    end
end # module

import .Withshow

d = Dict{Withshow.LetterHolder, Float32}(Withshow.LetterHolder([Withshow._A]) => 0.4, Withshow.LetterHolder([Withshow._U]) => 0.9, Withshow.LetterHolder([Withshow._E]) => 0.75)
for k in collect(keys(d))
    println(k, ", hash ", hash(first(Withshow.letter(k))))
end

@enum Fakeletter _A _U _E
d = Dict{Withshow.LetterHolder, Float32}(Withshow.LetterHolder([_A]) => 0.4, Withshow.LetterHolder([_U]) => 0.9, Withshow.LetterHolder([_E]) => 0.75)
for k in collect(keys(d))
    println(k, ", hash ", hash(first(Withshow.letter(k))))
end

module Withshowandhash
    export
        LetterHolder,
        _A,
        _E,
        _U

    @enum Fakeletter _A _E _U
    Base.hash(f::Fakeletter, h::UInt) = hash(string(f), h)
    # I think this is how Enums are hashed already?
    # https://github.com/JuliaLang/julia/blob/147bdf428cd14c979202678127d1618e425912d6/base/Enums.jl#L210C91-L210C91

    struct LetterHolder
        letter::Vector
    end
    letter(l::LetterHolder) = l.letter

    Base.show(io::IO, l::LetterHolder) = print(io, letter(l))
    Base.isless(l1::LetterHolder, l2::LetterHolder) = isless(letter(l1), letter(l2))
    function Base.hash(l::LetterHolder, h::UInt) 
        return hash(letter(l), h)
    end
    function Base.:(==)(l1::LetterHolder, l2::LetterHolder)
        return hash(l1) == hash(l2)
    end
end # module

import .Withshowandhash
d = Dict{Withshowandhash.LetterHolder, Float32}(Withshowandhash.LetterHolder([Withshowandhash._A]) => 0.4, Withshowandhash.LetterHolder([Withshowandhash._U]) => 0.9, Withshowandhash.LetterHolder([Withshowandhash._E]) => 0.75)
for k in collect(keys(d))
    println(k, ", hash ", hash(first(Withshowandhash.letter(k))))
end