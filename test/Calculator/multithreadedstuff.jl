using Random

rng = Xoshiro(999)
rngs = [Xoshiro(i) for i in 1:Threads.nthreads()]
# map(x -> Random.seed!(x, 42069), rngs)
b = rand(rng, 1:100, 10)
println(b)
Threads.@threads for i in eachindex(a)
    randnum = rand(rngs[Threads.threadid()], 1:100)
    println(i, " ", Threads.threadid(), " ", randnum)
    b[i] += randnum
end
println(b)



rng1 = Xoshiro(1)
rng2 = Xoshiro(2)
Random.seed!(rng2, 1)
println(rand(rng1))
println(rand(rng2))

Random.seed!(999)
b = rand(1:100, 10)
Threads.@threads for i in eachindex(a)
    b[i] += rand(1:10)
end
println(b)