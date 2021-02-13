using Tullio
using DataStructures

abstract type MinesweeperBoard end

function generate_neighbors(mines)
    K = Int8[1 1 1; 1 0 1; 1 1 1]
    M = vcat(
            zeros(Int8, size(mines, 2) + 2)',
            hcat(
                zeros(Int8, size(mines, 1)),
                mines,
                zeros(Int8, size(mines, 1))),
            zeros(Int8, size(mines, 2) + 2)')

    @tullio N[x+_, y+_] := M[x+dx,y+dy] * K[dx, dy]
end

struct SquareBoard <: MinesweeperBoard
    neighbors::Matrix{Int8}
    mines::BitArray{2}
    open::BitArray{2}
    flags::BitArray{2}
    SquareBoard(mines, visible=falses(size(mines)); flags=falses(size(mines))) =
        new(generate_neighbors(mines), mines, visible, flags)
end

function Base.print(io::IO, board::SquareBoard)
    rows, cols = size(board.neighbors)

    print(io, "╔")
    print(io, join(repeat(["═══"], cols), "╤"))
    println(io, "╗")

    for i in 1:rows
        print(io, "║")

        for j in 1:cols
            pos = CartesianIndex(i, j)
            if isflagged(board, pos)
                print(io, " ⚐ ")
            elseif !isopen(board, pos)
                print(io, "   ")
            elseif ismine(board, pos)
                print(io, " ☠ ")
            elseif mines(board, pos) == 0
                print(io, " 0 ")
            else
                print(io, " ", mines(board, pos), " ")
            end

            if j != cols
                print(io, "│")
            end
        end

        println(io, "║")

        if i != rows
            print(io, "╟")
            print(io, join(repeat(["───"], cols), "┼"))
            println(io, "╢")
        end
    end

    print(io, "╚")
    print(io, join(repeat(["═══"], cols), "╧"))
    print(io, "╝")
end

neighbors(board::SquareBoard, center) =
    filter(CartesianIndex(Tuple(center) .- 1):CartesianIndex(Tuple(center) .+ 1)) do pos
        pos in CartesianIndices(board.neighbors) && pos != center
    end

mines(board::SquareBoard, pos) = board.neighbors[pos]

isopen(board::SquareBoard, pos) = board.open[pos]
ismine(board::SquareBoard, pos) = board.mines[pos]
isflagged(board::SquareBoard, pos) = board.flags[pos]

open!(board::SquareBoard, pos) =
    if !isopen(board, pos)
        board.open[pos] = true
        return ismine(board, pos)
    end
toggle_flag!(board::SquareBoard, pos) =
    !isopen(board, pos) && (board.flags[pos] = !board.flags[pos])


function select!(board, pos; propagate=true)
    if propagate && mines(board, pos) == 0
        candidates = Deque{typeof(pos)}()
        push!(candidates, pos)

        while !isempty(candidates)
            next_empty = popfirst!(candidates)

            if mines(board, next_empty) == 0 && !isopen(board, next_empty)
                for adj_cell in neighbors(board, next_empty)
                    push!(candidates, adj_cell)
                end
            end

            open!(board, next_empty)
        end
    end

    open!(board, pos)
end

function chord!(board, pos)
    !isopen(board, pos) && return

    flagged_cells = count(neighbors(board, pos)) do adj_pos
        isflagged(board, adj_pos) || (isopen(board, adj_pos) && ismine(board, adj_pos))
    end

    if flagged_cells == mines(board, pos)
        for adj_pos in neighbors(board, pos)
            select!(board, adj_pos)
        end
    end
end

function superchord!(board::SquareBoard)
    while true
        already_open = count(board.open)

        # cells where flagged or are open mines
        known_mine_layout = board.flags .| (board.mines .& board.open)

        # known neighbors given the known mine layout
        known_neighbors = generate_neighbors(known_mine_layout)

        # positions for which it is okay to open all adjacent cells
        openable_adjacent_cells = (known_neighbors .== board.neighbors) .& board.open

        # cells that are adjacent to at least one cell that is "complete" (all nearby mines known)
        openable_cells = generate_neighbors(openable_adjacent_cells) .> 0

        for pos in findall(openable_cells)
            select!(board, pos)
        end

        already_open == count(board.open) && break
    end
end
