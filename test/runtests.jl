using AdvancedLayoutCalculator
using AdvancedLayoutCalculator.Keyboard
using AdvancedLayoutCalculator.AlcUtils
using AdvancedLayoutCalculator.TextProcessor
using Random
using Test
using Unitful
using BenchmarkTools
using Logging
using OrderedCollections
import AbstractAlgebra: Perm, cycles, setpermstyle
# BelowMinLevel, Debug = -1000, Info = 0, Warn = 1000, Error = 2000, AboveMaxLevel
debug_logger = ConsoleLogger(stdout, AboveMaxLevel) # level >= Logging.Debug
global_logger(debug_logger)



# include("test_customunits.jl")

# # text processor
include("TextProcessor/test_frequencyholder.jl")

# include("Keyboard/test_keyboard.jl")

include("Calculator/test_score.jl")

# include("Calculator/test_genetic_small.jl")
# include("Calculator/test_genetic_large.jl")

