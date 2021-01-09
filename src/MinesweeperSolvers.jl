module MinesweeperSolvers

# all package exports
export MinesweeperBoard,

SquareBoard

# source files
include("boards.jl")
include("games.jl")
include("solvers.jl")

end