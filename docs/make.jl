using AdvancedLayoutCalculator
using Documenter

DocMeta.setdocmeta!(AdvancedLayoutCalculator, :DocTestSetup, :(using AdvancedLayoutCalculator, AdvancedLayoutCalculator.AlcUtils, Unitful); recursive=true)

makedocs(;
    modules=[AdvancedLayoutCalculator],
    authors="Sh",
    repo="https://github.com/sandsquaretech/AdvancedLayoutCalculator.jl/blob/{commit}{path}#{line}",
    sitename="AdvancedLayoutCalculator.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://sandsquaretech.github.io/AdvancedLayoutCalculator.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Keyboard" => "keyboard.md",
        "Score functions" => "scorefunctions.md",
        "Calculators" => "calculators.md",
        "Utils" => "utils.md"
    ],
)

deploydocs(;
    repo="github.com/sandsquaretech/AdvancedLayoutCalculator.jl",
    devbranch="dev"
)
