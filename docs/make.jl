push!(LOAD_PATH, "../src/")

using Documenter
using MinesweeperSolvers

makedocs(
    sitename="MinesweeperSolvers.jl Documentation",
    format=Documenter.HTML(
        prettyurls=get(ENV, "CI", nothing) == "true"
    ),
    modules=[MinesweeperSolvers],
    pages=[
        "Home" => "index.md",
        "Quick Start" => "guide_quickstart.md",
        "API Reference" => "api_reference.md"
    ]
)

deploydocs(
    repo = "github.com/tmthyln/MinesweeperSolvers.jl.git",
    devbranch = "main",
    devurl="latest"
    )