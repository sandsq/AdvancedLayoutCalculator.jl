abstract type AbstractNgram end

struct Ngram <: AbstractNgram
    gram::Vector{Keycode}
end
Ngram(kcs::Keycode...) = Ngram(collect(kcs))
# constructor from string
gram(ng::Ngram) = ng.gram
@forward Ngram.gram Base.length, Base.iterate, Base.setindex!
Base.hash(ng::Ngram, h::UInt) = hash(gram(ng), h)
Base.:(==)(ng1::Ngram, ng2::Ngram) = hash(ng1) == hash(ng2)

function Base.getindex(ng::Ngram, i::Int)
    return Ngram(gram(ng)[i])
end
function Base.getindex(ng::Ngram, r::UnitRange{Int})
    return Ngram(gram(ng)[r])
end
# Base.iterate(ng::Ngram) = iterate(gram(ng))
# Base.iterate(ng::Ngram, state) = iterate(gram(ng), state)
function ngram2string(ng::Ngram)
    out = ""
    for gram in ng
        out *= string(gram)[2:end]
    end
    return out
end
function Base.isless(ng1::Ngram, ng2::Ngram)
    return isless(ngram2string(ng1), ngram2string(ng2))
end
function Base.append!(ng1::Ngram, ng2::Ngram)
    return Ngram(append!(gram(ng1), gram(ng2)))
end
function Base.show(io::IO, ng::Ngram)
    print(io, join(string.(ng)))
end

macro ngram_str(s)
    protokeycodes = split(s, "_")
    seq = Vector{Keycode}()
    for p in protokeycodes
        if length(p) == 0 continue end
        keycode = eval(Meta.parse("_$p"))
        push!(seq, keycode)
    end
    return Ngram(seq)
end

