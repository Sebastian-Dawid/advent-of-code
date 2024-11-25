using DataStructures

n4(p) = [p .- (0,1), p .- (1,0), p .+ (1,0), p .+ (0,1)]

function find_adjacent(start, grid, terminals)
    adj = []
    q = Deque{Tuple}()
    push!(q, (start, 0, Set([start])))
    while !isempty(q)
        (pt, len, seen) = popfirst!(q)
        if pt ∈ terminals && pt != start
            push!(adj, (pt, len))
            continue
        end

        neighbors = [ n for n ∈ n4(pt) if 1 <= n[1] <= length(grid[1]) && 1 <= n[2] <= length(grid) && n ∉ seen && grid[n[2]][n[1]] != '#' ]
        if length(neighbors) > 1 && pt != start
            push!(adj, (pt, len))
            continue
        end

        for n ∈ neighbors
            push!(seen, n)
            push!(q, (n, len+1, copy(seen)))
        end
    end
    return adj
end

function build_graph(grid, start, _end)
    (graph, seen, q) = (DefaultDict(() -> Vector()), Set(), [start])
    while !isempty(q)
        p = pop!(q)
        if p ∈ seen
            continue
        end

        push!(seen, p)

        for (n, l) ∈ find_adjacent(p, grid, [start, _end])
            push!(graph[p], (n, l))
            if n ∉ seen
                push!(q, n)
            end
        end
    end
    return graph
end

function longest_path(graph, start, _end)
    (longest, q) = (0, [(start, 0, Set([start]))])
    while !isempty(q)
        (p, l, seen) = pop!(q)
        if (p == _end)
            longest = max(longest, l)
            continue
        end
        for (n, nl) ∈ graph[p]
            if n ∉ seen
                _seen = copy(seen)
                push!(_seen, n)
                push!(q, (n, l + nl, copy(_seen)))
            end
        end
    end
    return longest
end

function solve(input)
    start = (2, 1)
    _end = (length(input[1]) - 1, length(input))
    graph = build_graph(input, start, _end)
    return longest_path(graph, start, _end)
end

if abspath(PROGRAM_FILE) == @__FILE__
    input = readlines(ARGS[1])
    input = [replace(s, r"[\^><v]" => ".") for s in input]
    println(solve(input))
end
