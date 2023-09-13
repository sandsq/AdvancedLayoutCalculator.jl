# using Distributed
# addprocs(7)
# println(nworkers())
# println(nprocs())

using BenchmarkTools

# @everywhere begin
#     using Pkg; Pkg.activate(@__DIR__)
#     Pkg.instantiate(); Pkg.precompile()
# end





# @everywhere begin
    using AdvancedLayoutCalculator
    using AdvancedLayoutCalculator.Alcutils
    pvecvec = [[Key()], [Key(), Key(_E, false), Key()]]
    pvecvec2 = [[Key(_A, false)], [Key(), Key(), Key()]]
    template = Keymap(Layer(pvecvec), Layer(pvecvec2))
    glc = GLC(CalcConfig(10000), BasicScoreFunction())
# end


# solns = calculatelayout!(glc, template, template, Dict(_A => 100., _E => 10., _O => 5., _U => 4., _SPC => 11., _LSFT => 3., _LCTL => 9.))
# println(length(solns))
@btime calculatelayout!(glc, template, template, Dict(_A => 100., _E => 10., _O => 5., _U => 4., _SPC => 11., _LSFT => 3., _LCTL => 9.))
# 167.926 ms (12753 allocations: 421.00 KiB) for addprocs(1), 28.934 ms (12735 allocations: 423.78 KiB) for addprocs(7), 100*1000 instances
# 1.114 s (1301815 allocations: 41.36 MiB) for addprocs(1), 353.161 ms (1290593 allocations: 41.07 MiB) for addprocs(7), 10000*12 instances
# 203.393 ms (6540053 allocations: 516.13 MiB) no distributed, 342.400 ms (1290598 allocations: 41.08 MiB) for addprocs(7), "
# 1.914 s (64860053 allocations: 5.03 GiB), 444.635 ms (1293292 allocations: 41.16 MiB), 10000*120 instances
# so when the function has a lot of work, pmap helps


