abstract type Cell end
struct EmptyCell <: Cell end
struct BoundaryCell <: Cell end
struct SandCell <: Cell end

Base.Char(c::EmptyCell) = ' '
Base.Char(c::BoundaryCell) = 'x'
Base.Char(c::SandCell) = '▒'
Base.show(io::IO, c::C where C <: Cell) = print(io, Char(c))

struct Universe
    cells::Matrix{C where C <: Cell}
    width::Int
    height::Int
end

function Universe(width::Int, height::Int)
    Universe(Matrix{Cell}(undef, height, width), width, height)
end

function Base.map!(f::Function, u::Universe)
    for i in 1:u.height
        for j in 1:u.width
            @inbounds u.cells[i, j] = f(u, i, j)
        end
    end
end

function Base.getindex(u::Universe, i::Int, j::Int)
    if (i, j) ∈ u
        u.cells[i, j]
    else
        BoundaryCell()
    end
end

@inbounds function Base.setindex!(u::Universe, c::C where C <: Cell, i, j)
    if  (i, j) ∈ u
        u.cells[i, j] = c 
    end
end

Base.in(ij::Tuple{Int, Int}, u::Universe) = in(ij[1], ij[2], u)
Base.in(i::Int, j::Int, u::Universe) = (i ≤ u.height) && (j ≤ u.width) && (i ≥ 1 && j ≥ 1)

function update!(u::Universe)
    for i in u.height:-1:1
        for j in 1:u.width
            update!(u, i, j)
        end
    end
end

function update!(u::Universe, i::Int, j::Int)
    update!(u, i, j, u[i, j])
end

function update!(u::Universe, i::Int, j::Int, c::EmptyCell)
end

function update!(u::Universe, i::Int, j::Int, c::SandCell)
    if u[i+1, j] == EmptyCell()
        u[i, j] = EmptyCell()
        u[i+1, j] = SandCell()
    elseif u[i+1, j] == SandCell()
        spread_left = u[i+1, j-1] == EmptyCell()
        spread_right = u[i+1, j+1] == EmptyCell()
        
        if spread_left || spread_right
            u[i, j] = EmptyCell()
        end

        if spread_left && spread_right
            if rand() > 0.50
                u[i+1, j-1] = SandCell()
            else
                u[i+1, j+1] = SandCell()
            end
        elseif spread_left
                u[i+1, j-1] = SandCell()
        elseif spread_right
                u[i+1, j+1] = SandCell()
        end
    end
end

function Base.show(io::IO, u::Universe)
    for i in 1:u.height
        for j in 1:u.width
            print(io, Char(u[i, j]))
        end
        print(io, '\n')
    end
end

function clear!(u::Universe)
    map!((u, i, j) -> EmptyCell(), u)
end

u = Universe(10, 10);
map!((u, i, j) -> ifelse(rand() > 0.5, SandCell(), EmptyCell()), u)
display(u)
update!(u)

u = Universe(10, 10);
clear!(u)

begin
    print("\33[2J")
    for i in 1:50
        print("\33[2J")
        if i < 25
            u[1, 5] = SandCell()
        end
        display(u)
        update!(u)
        sleep(0.1)
    end
end