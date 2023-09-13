println("benchmarking mutate function")
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
import AdvancedLayoutCalculator.Calculators: mutate!, swapmutation!, replacementpointmutation!


numsamples=100

io = IOContext(stdout)
global_logger(ConsoleLogger(stdout, AboveMaxLevel))

rng = Xoshiro(1)

cc = CalculatorConfig(populationsize=1000, maxiter=200)
sf = BasicScoreFunction()
glc = GeneticLayoutCalculator(cc, sf)
km = gen4x12keymap(;numlayers=3, layerswitchmoveability=true)
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

el = gen4x12effortlayer()
fh = BasicFrequencyTemplate

km1, _ = genrandomkeymap(rng, km, getuniquekeycodes(fh))

# mutate!(rng, lc, km1, getuniquekeycodes(fh))

# benchswap = @benchmark swapmutation!($rng, $glc, $km1) samples=numsamples
# benchreplace = @benchmark replacementpointmutation!($rng, $glc, $km1, getuniquekeycodes($fh)) samples=numsamples
# println("@@@@ swap")
# show(io, MIME("text/plain"), benchswap)
# println("\n@@@@ replace")
# show(io, MIME("text/plain"), benchreplace)

sf = BasicScoreFunction()
benchscore = @benchmark calculatescore(sf, km1, fh)


println("\n@@@@ calculatescore")
show(io, MIME("text/plain"), benchscore)