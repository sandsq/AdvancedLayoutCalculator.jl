module Calculators

export
    checkfrequencysize,
    CalculatorConfig,
    RouletteSelector,
    BestScoresSelector,
    GeneticLayoutCalculator,
    calculatorconfig,
    scorefunction,
    calculatelayout

# using Distributed
using Statistics
using Random
import Random: default_rng
using Logging
using OrderedCollections
using DataStructures
using ProgressBars
using Distributed
using AdvancedLayoutCalculator
using AdvancedLayoutCalculator.Keyboard
using AdvancedLayoutCalculator.AlcUtils
using AdvancedLayoutCalculator.TextProcessor
import AbstractAlgebra: Perm, cycles, SymmetricGroup, @perm_str
using UUIDs
using JLD2
import YAML
using Combinatorics
using UnicodePlots

"""
    checkfrequencysize
Checks to make sure the keymap and the number of unique keycodes to be placed in the keymap are compatible.
"""
function checkfrequencysize(sf::S, keymap::K, frequencies::Dict{Keycode, Float32}) where {S <: AbstractScoreFunction, K <: AbstractKeymap}
#     if length(keys(frequencies)) > numelements(keymap)
#         error("There are more keycodes to place than spots in the keymap to place them.")
#     end
#     return nothing
end


abstract type AbstractLayoutCalculator end


include("GeneticLayoutCalculator.jl")


end # module