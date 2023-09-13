println("calcing layout")

using AdvancedLayoutCalculator
using AdvancedLayoutCalculator.Keyboard
using AdvancedLayoutCalculator.AlcUtils
using AdvancedLayoutCalculator.TextProcessor
using BenchmarkTools
using Logging
using Random
import AdvancedLayoutCalculator.Calculators: _shortuuid
using Dates

runid = _shortuuid()



io = open("misc/runlogs/$runid.txt", "w")
logger = ConsoleLogger(io, Info)

with_logger(logger) do



# io = IOContext(stdout)

# done/tried todo: remove space from 3-grams?
# todo: see if more threads+gc leads to speedup?
# done todo: large popsize, more iterations, from initial blank templates
# doneish? todo: increase effort of 1, 2 and 2, 2
# done todo: pretty print effort layer and fingermap layer for easy copy paste back to custom string literal
# done todo: retry "standard" effortmap of rows 2 and 4 being low weight rather than 1 and 2
# todo: space back in ngrams
cc = CalculatorConfig(
    rundescription="v0.7.0, 4x12 layout, reduced crossover weight, initial keymap only one of each",
    # rundescription="v0.8.1, layer switch in non-3rd row",
    populationsize=5000, maxiter=150, swapmutationweight=1.0, identityweight=0.0, replacepointmutationweight=1.0, crossoverweight=0.5,
    selector=BestScoresSelector(
        # xs=[0,   0.15, 0.4,  0.5,  0.6,  0.7, 0.75, 0.8, 1.0], 
        # ys=[0.5, 0.35, 0.4,  0.25, 0.15, 0.0, 0.1,  0.0, 0.0]), 
        xs=[0,   0.085, 0.34,  0.5],
        ys=[0.5, 0.1, 0.05, 0.0]),
        # xs=[0],
        # ys=[0]),
    # earlystopping = (x, y) -> return false
    )
sf = AdvancedScoreFunction(
    samefingerpenalty = 4.0,
    # multirowpenalty = 3.0
)
glc = GeneticLayoutCalculator(cc, sf)


shifts = Commonshiftedsymbols
delete!(shifts, _UNDS)
ngramconfig = Ngramconfig(
    description = "test",
    shiftedsymbols = shifts,
    maxgrams = 4,
    scaletype = :ngramlength,
    topns = [-1, 100, 100, 50, 50]
)

fh = NgramFrequencyHolder(
    ["./test/data/2701-0.txt", "./test/data/1342-0.txt"];#, "./test/data/829-0.txt", "./test/data/76.txt"]; 
    config=ngramconfig)#, exclusions=Commonreplacementexclusions)
frequencies(fh)[1][ngram"_GRV"] = frequencies(fh)[1][ngram"_SCLN"]/2
@info ngramconfig

# km = gen5x6keymap(;numlayers=3, template=:innerthumbbspc)
# km = gen5x7keymap(;numlayers=3, template=:default)
km = gen4x12keymap(;numlayers=3, template=:default)

# # l1test = layer"""
# #     Q    SLSH     SFT     ENT     DOT    QUOT
# #   TAB       E       H       T       I    COMM
# #  LCTL       S       E      LS       A       W
# #    LS       N       I       V       F       K
# #   GUI    CAPS     ALT      LS    BSPC     SPC
# # """
# # l2test = layer"""
# # ESC       Z    MINS       X       L     GRV
# # SCLN       Y       B     ENT       G       T
# # LCTL       U       O      LS       R       C
# #   S       M       N       J       D       P
# # GUI      __     ALT      __      __       L
# # """
# # l3test = layer"""
# # LPRN  RPRN   EQL  SLSH  ASTR  MINS
# # LBRC  RBRC     1     2     3  PLUS
# # LCBR  RCBR     4     5     6   ENT
# #  LS  COMM     7     8     9  UNDS
# #  __    __  COLN     0   DOT   SFT
# # """
# layers = layers"""
# --------
#        Q    SLSH     SFT     ENT     DOT    QUOT
#      TAB       E       H       T       I    COMM
#     LCTL       S       E      LS       A       W
#       LS       N       I       V       F       K
#      GUI    CAPS     ALT      LS    BSPC     SPC

# --------
#      ESC       Z    MINS       X       L     GRV
#     SCLN       Y       B     ENT       G       T
#     LCTL       U       O      LS       R       C
#        S       M       N       J       D       P
#      GUI      __     ALT      __      __       L

# --------
#     LPRN    RPRN     EQL    SLSH    ASTR    MINS
#     LBRC    RBRC       1       2       3    PLUS
#     LCBR    RCBR       4       5       6     ENT
#       LS    COMM       7       8       9    UNDS
#       __      __    COLN       0     DOT     SFT
# """

# lsmtest = LayerSwitchmap(KL(), KL(1, 3, 4), KL(1, 4, 1), KL(1, 5, 4))
# kmtest = Keymap(layers, layerswitches=lsmtest, effortlayer=effortlayer(km), fingermaplayer=fingermaplayer(km))
# println(kmtest, "\n", calculatescore(sf, kmtest, fh, getngrams(fh)))
# exit()

open("misc/runlogs/runindex.txt", "a") do fi
    print(fi, "\n", now(), "\t", runid, "\t", glc.calculatorconfig.rundescription)
end

# km = gen5x6keymap(;numlayers=3, template=:innerthumbbspc)
# println(io, km)#, "\n", calculatescore(sf, km, fh, getngrams(fh)))



# kmtbs = gen5x6keymap(;numlayers = 3, template=:standardthumbls)
# println(io, kmtbs)

# km0552 = gen5x6keymap(;numlayers = 3, template=:v055_2)
# println(io, km0552)


# km0515 = gen5x6keymap(;numlayers = 3, template=:v0515)
# println(io, km0515)


# km070 = gen5x6keymap(;numlayers = 3, template=:v070)
# println(io, km070)

# km073 = gen5x6keymap(;numlayers = 3, template=:v073)
# println(io, km073)

# km075 = gen5x6keymap(;numlayers = 3, template=:v075)
# println(io, km075)

# km071 = gen5x6keymap(;numlayers = 3, template=:v071)
# println(io, km071)

# km090 = gen5x6keymap(;numlayers = 3, template=:v090)
# println(io, km090)

# km2 = gen5x6keymap(;numlayers=3, template=:v1)
# println(io, km2, "\n", calculatescore(sf, km2, fh, getngrams(fh)))

# km3 = gen5x6keymap(;numlayers=3, template=:v2)
# println(io, km3, "\n", calculatescore(sf, km3, fh, getngrams(fh)))

# km4 = gen5x6keymap(;numlayers=3, template=:v3)
# println(io, km4, "\n", calculatescore(sf, km4, fh, getngrams(fh)))

# km5 = gen5x6keymap(;numlayers=3, template=:v4)
# println(io, km5, "\n", calculatescore(sf, km5, fh, getngrams(fh)))

# km6 = gen5x6keymap(;numlayers=3, template=:v5)
# println(io, km6, "\n", calculatescore(sf, km6, fh, getngrams(fh)))

# km7 = gen5x6keymap(;numlayers=3, template=:v6)
# println(io, km7, "\n", calculatescore(sf, km7, fh, getngrams(fh)))

# km8 = gen5x6keymap(;numlayers=3, template=:v7)
# println(io, km8, "\n", calculatescore(sf, km8, fh, getngrams(fh)))

# km9 = gen5x6keymap(;numlayers=3, template=:v8)
# println(io, km9, "\n", calculatescore(sf, km9, fh, getngrams(fh)))

# km10 = gen5x6keymap(;numlayers=3, template=:v9)
# println(io, km10, "\n", calculatescore(sf, km10, fh, getngrams(fh)))

# km11 = gen5x6keymap(;numlayers=3, template=:v10)
# println(io, km11, "\n", calculatescore(sf, km11, fh, getngrams(fh)))

# km12 = gen5x6keymap(;numlayers=3, template=:v11)
# println(io, km12, "\n", calculatescore(sf, km12, fh, getngrams(fh)))

# km13 = gen5x6keymap(;numlayers=3, template=:v12)
# println(io, km13, "\n", calculatescore(sf, km13, fh, getngrams(fh)))

# km056 = gen5x6keymap(;numlayers=3, template=:v056)
# println(io, km056, "\n", calculatescore(sf, km056, fh, getngrams(fh)))


rng = Xoshiro(11)

t0 = time()
@time km, s1, s2, s3 = calculatelayout(rng, glc, km, fh; symmetricshift=false,
#  additionaltemplates=[km3, km4, km5, km6, km7, km8, km9, km10, km11, km12, km13], 
#  additionaltemplates=[km4, km5, km12, km, km056], 
    # additionaltemplates=[km12, km, km056], # s and space fixed
    # additionaltemplates=[km0515],
 checkpointdir=runid, io=io)
 t1 = time() - t0
 @info "rough time $(t1)"
 open("misc/runlogs/runindex.txt", "a") do fi
    print(fi, "\t", t1)
end
# println(io, km)
println(io, s1)
println(io, s2)
println(io, s3)
println(io, "Min of the mins ", minimum(s2))
finscore = calculatescore(sf, km, fh, getngrams(fh))
println(io, "Final score ", finscore)


# 1000, 5, serial: 18.044743 seconds (380.59 M allocations: 22.514 GiB, 19.50% gc time, 26.91% compilation time)
# 1000, 5, 8 threads:  12.533614 seconds (378.76 M allocations: 22.397 GiB, 22.68% gc time, 35.31% compilation time)

# 1000, 100, serial: 407.794696 seconds (9.83 G allocations: 673.710 GiB, 29.13% gc time, 1.08% compilation time)
# 1000, 100, 8 threads: 224.865650 seconds (9.83 G allocations: 673.710 GiB, 35.89% gc time, 2.03% compilation time)
# 1000, 100, 8 threads, include crossover/mutate: 159.080556 seconds (9.94 G allocations: 684.323 GiB, 63.54% gc time, 16.91% compilation time)


end
close(io)