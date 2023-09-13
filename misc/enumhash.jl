module FakeletterModule
export
    Fakeletter, _A, _B, _C, Thing

@enum Fakeletter _A _B _C
struct Thing
    t::Int
end
Base.hash(t::Thing, h::UInt) = hash(t.t, h)
end # module

import .FakeletterModule: _A, _B, _C, Thing
letts = [_A, _B, _C]
d = Dict{FakeletterModule.Fakeletter, Float32}(_A => 0.1, _B => 0.1, _C => 0.1)
println("enum inside module")
for l in letts
    println(l, " ", hash(l))
end
println(collect(keys(d)))
println(hash(Thing(5)))

@enum Fakeletter _A2 _B2 _C2
letts2 = [_A2, _B2, _C2]
d2 = Dict{Fakeletter, Float32}(_A2 => 0.1, _B2 => 0.1, _C2 => 0.1)
println("enum outside module")
for l in letts2
    println(l, " ", hash(l))
end
println(collect(keys(d2)))

