module AdvancedLayoutCalculator

# notes to self
# @@@@@@@@@@@@@
# anything exported here is available via `using AdvancedLayoutCalculator`
# any submodules here are available via `using AdvancedLayoutCalculator.{submodule}`
# need to decide what should be available from ALC and what should available from submodules
# in Graphs.jl for example, experimental algorithms are in `Graphs.Experimental`, while general graph utilities are available in `Graphs`

    include("AlcUtils.jl")
    using .AlcUtils

    include("Keyboard/Keyboard.jl")
    using .Keyboard

    include("TextProcessor/TextProcessor.jl")
    using .TextProcessor

    include("Calculator/ScoreFunctions.jl")
    using .ScoreFunctions
    export
        AbstractScoreFunction,
        checkauxlayersize,
        BasicScoreFunction,
        scoresequence,
        calculatescore,
        AdvancedScoreFunction

    include("Calculator/Calculators.jl")
    using .Calculators
    export
        checkfrequencysize,
        CalculatorConfig,
        RouletteSelector,
        BestScoresSelector,
        GeneticLayoutCalculator,
        calculatorconfig,
        scorefunction,
        calculatelayout


        

    

end

