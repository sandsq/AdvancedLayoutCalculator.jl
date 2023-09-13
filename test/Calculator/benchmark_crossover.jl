println("benchmarking crossover function")
using AdvancedLayoutCalculator
println("loaded alc")
using AdvancedLayoutCalculator.Keyboard
using AdvancedLayoutCalculator.AlcUtils
using AdvancedLayoutCalculator.TextProcessor
println("loaded alc submodules")
using BenchmarkTools
using Logging
using Random
using AbstractAlgebra
import AdvancedLayoutCalculator.Calculators: _movelayerswitchesfrom1to2!, _movesymmetrics1to2!, getbasekmpermutation, getkmpermutation, _applykmpermutation!, crossover!

numsamples=100

io = IOContext(stdout)
global_logger(ConsoleLogger(stdout, AboveMaxLevel))

rng = Xoshiro(1)

cc = CalculatorConfig(populationsize=1000, maxiter=200)
sf = BasicScoreFunction()
glc = GeneticLayoutCalculator(cc, sf)
km = gen4x12keymap(3, 4, 12; layerswitchmoveability=true)
km[KeyLocation(1, (1, 1))] = Key(_TAB, false)
km[KeyLocation(1, (4, 6))] = Key(_SPC, false)
km[KeyLocation(1, (4, 7))] = Key(_BSPC, false)
km[KeyLocation(3, (3, 11))] = Key(_LCTL, false)

km[KeyLocation(2, (1, 2))] = Key(_1, false)
km[KeyLocation(2, (1, 3))] = Key(_2, false)
km[KeyLocation(2, (1, 4))] = Key(_3, false)
km[KeyLocation(2, (1, 5))] = Key(_4, false)
km[KeyLocation(2, (1, 6))] = Key(_5, false)

km[KeyLocation(2, (2, 2))] = Key(_6, false)
km[KeyLocation(2, (2, 3))] = Key(_7, false)
km[KeyLocation(2, (2, 4))] = Key(_8, false)
km[KeyLocation(2, (2, 5))] = Key(_9, false)
km[KeyLocation(2, (2, 6))] = Key(_0, false)

km[KeyLocation(1, (3, 1))] = Key(_SFT, true, true)
km[KeyLocation(1, (3, 12))] = Key(_SFT, true, true)

# el = gen4x12effortlayer()
fh = BasicFrequencyTemplate

km1, _ = genrandomkeymap(rng, km, getuniquekeycodes(fh))
km2, _ = genrandomkeymap(rng, km, getuniquekeycodes(fh))
# t = @benchmark crossover!($rng, $km1, $km2) samples=numsamples
# show(io, MIME("text/plain"), t)



benchls = @benchmark _movelayerswitchesfrom1to2!($km1, $km2)  samples=numsamples
_, proceed = _movelayerswitchesfrom1to2!(km1, km2) 
if !proceed
    opcounts.identitycount += 1
    return km1
end
if km1 == km2
    opcounts.identitycount += 1
    return km1
end
benchsymm = @benchmark _movesymmetrics1to2!($km1, $km2) samples=numsamples
_movesymmetrics1to2!(km1, km2)

benchbase = @benchmark getbasekmpermutation($km1, $km2) samples=numsamples
basemap = getbasekmpermutation(km1, km2)

benchperm = @benchmark getkmpermutation($km1, $basemap) samples=numsamples
σ, layerswitchperms = getkmpermutation(km1, basemap)

τ, _ = getkmpermutation(km2, basemap)

permsize = length(σ.d)

g = SymmetricGroup(permsize)

ν = σ * inv(τ) #* layerswitchperms
νcycles = cycles(ν)

newparr = Vector{Vector{Int}}()
push!(newparr, cycles(σ)...)
for c in νcycles
    if length(c) == 1 || length(c) == 2 continue end
    shiftamount = 1:(length(c)-1)
    ĉ = circshift(c, rand(rng, shiftamount))
    ĉ = ĉ[1:Int(ceil(length(ĉ)/2))]
    push!(newparr, ĉ)
end
str1 = map(x -> "($(join(x, ", ")))", newparr)
newandshifted = reduce(*, g.(str1))

benchapply = @benchmark _applykmpermutation!($rng, $km1, $basemap, $newandshifted) samples=numsamples
_applykmpermutation!(rng, km1, basemap, newandshifted)


# 1000 pop, 200 iter, 2m:29s pre opts
# with
# without [02:35<00:00, 1it/s] # swap count: 50018, layer switch swap count: 2422, identity count: 30971, replace count: 50293, crossover count: 66296
# most of the time savings came from eliminating the separate km2 pass in creating the basemap


println("@@@@ initial layer swaps")
show(io, MIME("text/plain"), benchls)
println("\n@@@@ initial symm swaps")
show(io, MIME("text/plain"), benchsymm)
# @@@@ initial symm swaps
# BenchmarkTools.Trial: 100 samples with 6 evaluations.
#  Range (min … max):  5.167 μs …   9.050 μs  ┊ GC (min … max): 0.00% … 0.00%       
#  Time  (median):     5.733 μs               ┊ GC (median):    0.00%
#  Time  (mean ± σ):   5.895 μs ± 739.643 ns  ┊ GC (mean ± σ):  0.00% ± 0.00%       

#    ▄▄  ▁       █▄▇▁
#   ▅███▆██▆▅▁▅▃▆█████▅▃▁▃▁▁▁▁▁▁▁▁▃▅▃▁▁▁▃▃▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▃▆▆▃▅▃ ▃
#   5.17 μs         Histogram: frequency by time        7.65 μs <

#  Memory estimate: 12.67 KiB, allocs estimate: 473.
# looping through special keys only
# @@@@ initial symm swaps
# BenchmarkTools.Trial: 100 samples with 7 evaluations.
#  Range (min … max):  4.314 μs … 10.729 μs  ┊ GC (min … max): 0.00% … 0.00%        
#  Time  (median):     4.786 μs              ┊ GC (median):    0.00%
#  Time  (mean ± σ):   5.096 μs ±  1.163 μs  ┊ GC (mean ± σ):  0.00% ± 0.00%        

#     ▁▇█▂
#   ▆▆████▄▃▃▃▄▅▃▁▁▃▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▃▁▁▃▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▃ ▃
#   4.31 μs        Histogram: frequency by time        10.7 μs <

#  Memory estimate: 12.06 KiB, allocs estimate: 187.
println("\n@@@@ basemap")
show(io, MIME("text/plain"), benchbase)
# a4h2o
# iterate through km for special cases
# @@@@ basemap
# BenchmarkTools.Trial: 100 samples with 1 evaluation.
#  Range (min … max):  287.300 μs …   2.521 ms  ┊ GC (min … max): 0.00% … 77.98%    
#  Time  (median):     345.050 μs               ┊ GC (median):    0.00%
#  Time  (mean ± σ):   368.019 μs ± 222.341 μs  ┊ GC (mean ± σ):  5.34% ±  7.80%    

#        ▄▄    ██      ▂
#   ▄██▄▆██▃▄▄▃██▇▄▁▃▄▃█▄▁▁▃▃▁▃▄▁▁▃▁▃▁▁▁▁▁▁▁▁▁▁▃▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▃ ▃
#   287 μs           Histogram: frequency by time          594 μs <

#  Memory estimate: 494.86 KiB, allocs estimate: 11356.
# iterate through special cases only
# @@@@ basemap
# BenchmarkTools.Trial: 100 samples with 1 evaluation.
#  Range (min … max):  272.900 μs …   2.216 ms  ┊ GC (min … max): 0.00% … 83.92%    
#  Time  (median):     304.900 μs               ┊ GC (median):    0.00%
#  Time  (mean ± σ):   340.079 μs ± 193.405 μs  ┊ GC (mean ± σ):  5.47% ±  8.39%    

#    ▃   █▅▂              █▂
#   ▆██▅████▅▆▃▅▅▇▃▅▃▃▃▁▁▃███▅▃▁▁▁▁▅▁▃▁▁▁▃▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▃ ▃
#   273 μs           Histogram: frequency by time          501 μs <

#  Memory estimate: 454.16 KiB, allocs estimate: 9975.
# single pass for non-special
# @@@@ basemap
# BenchmarkTools.Trial: 100 samples with 1 evaluation.
#  Range (min … max):  176.600 μs … 281.300 μs  ┊ GC (min … max): 0.00% … 0.00%     
#  Time  (median):     193.900 μs               ┊ GC (median):    0.00%
#  Time  (mean ± σ):   199.728 μs ±  20.656 μs  ┊ GC (mean ± σ):  0.00% ± 0.00%     

#   ▆▃▁▄▄    ▃█ ▁ ▄▁        ▁  ▄
#   █████▆▆▁▁██▇█▁██▆▄▄▄▇▄▁▆█▄▁█▁▄▆▄▁▆▁▇▁▁▁▁▁▁▁▄▁▁▁▁▁▁▆▄▁▁▄▁▁▁▁▁▄ ▄
#   177 μs           Histogram: frequency by time          262 μs <

#  Memory estimate: 300.08 KiB, allocs estimate: 6700.
println("\n@@@@ getting perm")
show(io, MIME("text/plain"), benchperm)
println("\n@@@@@ applying perm")
show(io, MIME("text/plain"), benchapply)