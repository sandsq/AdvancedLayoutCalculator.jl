using BenchmarkTools



# # fake Keys
abstract type AbstractMini end

struct Mini{S <: Union{Float32, Int}} <: AbstractMini
    v::S
end

## this is what we have 2023 june 2
struct Mini2 <: AbstractMini
    v::Union{Float32, Int}
end

struct MiniBad <: AbstractMini
    v
end
value(m::AbstractMini) = m.v

begin
    println("Fake keys")
    n = 1000

    m1 = Mini.(rand(n))
    m2 = Mini2.(rand(n))
    mbad = MiniBad.(rand(n))

    # @btime sum(value.(m1))
    # @btime sum(value.(m2))
    # @btime sum(value.(mbad))
end



# Generic type param testing
abstract type AbstractProto end

# this is what we have 2023 june 2
struct Proto{T} <: AbstractProto
    v::Vector{Vector{T}}
end

struct ProtoDual{T <: Vector{Union{Mini{Int}, Mini{Float32}}}} <: AbstractProto
    v::Vector{T}
end


struct Proto2 <: AbstractProto
    v::Vector{Vector{Float32}}
end


struct Proto3{T <: AbstractFloat} <: AbstractProto
    v::Vector{Vector{T}}
end


struct ProtoBad <: AbstractProto
    v::Vector{Vector{Any}}
end

struct Proto5 <: AbstractProto
    v::Vector{Vector{Union{Float32, Int}}}
end

value(p::AbstractProto) = p.v

function busywork(p::AbstractProto)
    sum = 0
    for i in eachindex(value(p))
        for j in eachindex(value(p)[i])
            sum += value(p)[i][j]
        end
    end
end

function busywork2(p::Proto{L}) where {L <: AbstractFloat}
    sum = 0
    for i in eachindex(value(p))
        for j in eachindex(value(p)[i])
            sum += value(p)[i][j]
        end
    end
end

# function busywork3(p::Proto{AbstractFloat})
#     sum = 0
#     for i in eachindex(value(p))
#         for j in eachindex(value(p)[i])
#             sum += value(p)[i][j]
#         end
#     end
# end

begin
    println("Generic vec of vec")
    n = 1000
    v = [rand(1000), rand(1000)]
    p = Proto([rand(n), rand(n)])
    p2 = Proto2([rand(n), rand(n)])
    p3 = Proto3([rand(n), rand(n)])
    p4 = ProtoBad([rand(n), rand(n)])
    p4_2 = ProtoBad([rand(n), rand(Int, n)])
    p5 = Proto5([rand(n), rand(Int, n)])

    
    # @btime busywork3(p)

    # @btime value(p);
    # @btime value(p2);
    # @btime value(p3);
    # @btime value(p4);
    # @btime value(p4_2);
    # @btime value(p5);

    @btime busywork(p);
    @btime busywork2(p);
    # @btime busywork(p2);
    # @btime busywork(p3);
    # @btime busywork(p4);
    # @btime busywork(p4_2);
    # @btime busywork(p5);
end




# # Fake Layers

abstract type AbstractFake end

struct Fake <: AbstractFake
    v::ProtoDual
end

struct Fake2 <: AbstractFake
    v::Proto{Mini2}
end

struct FakeBad <: AbstractFake
    v::Proto{MiniBad}
end

value(p::AbstractFake) = p.v

function busywork(p::AbstractFake)
    sum = 0
    for i in eachindex(value(value(p)))
        for j in eachindex(value(value(p))[i])
            sum += value(value(value(p))[i][j])
        end
    end
end


begin
    println("Fake layers")
    n = 1000
    println(typeof(Mini.(rand(5))))
    println(typeof(Vector{Vector{Union{Mini{Int}, Mini{Float32}}}}([Mini.(rand(n)), Mini.(rand(Int, n-1))])))
    println(typeof([Mini2.(rand(n)), Mini2.(rand(Int, n-1))]))

    f = Fake(ProtoDual(Vector{Vector{Union{Mini{Int}, Mini{Float32}}}}([Mini.(rand(n)), Mini.(rand(Int, n-1))])))
    f2 = Fake2(Proto([Mini2.(rand(n)), Mini2.(rand(Int, n-1))]))
    fbad = FakeBad(Proto([MiniBad.(rand(n)), MiniBad.(rand(Int, n-1))]))

    @btime busywork(f);
    @btime busywork(f2);
    @btime busywork(fbad);
end
