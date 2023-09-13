using Random

Random.seed!(0)

function busywork(l::Layer)
    sum = 0.0
    for i in eachindex(l)
        for j in eachindex(l[i])
            k = l[i, j]
            sum += value(k) #* convert(Int, ismoveable(k))
            # sum += rand() * value(k) * convert(Int, ismoveable(k)) 
        end
    end
    # println(sum)
end

# practically we won't need to deal with a lot of keys, but still
keys = Vector{Vector{Key}}()
for i in 1:5
    row = Vector{Key}()
    for j in 1:10000
        v = rand()
        k = Key(v, rand(Bool))
        push!(row, k)
    end
    push!(keys, row)
end
l = Layer(keys)
println(dimensionsgran(l))

# busywork(l)
@btime busywork(l) # 41.100 μs (0 allocations: 0 bytes), 24915.540984147403



