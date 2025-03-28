"""
    arrays(f::ROOTFile, treename)

Reads all branches from a tree.
"""
function arrays(f::ROOTFile, treename)
    names = keys(f[treename])
    res = Vector{Vector}(undef, length(names))
    Threads.@threads for i in eachindex(names)
        res[i] = array(f, "$treename/$(names[i])")
    end
    return res
end

"""
    array(f::ROOTFile, path; raw=false)

Reads an array from a branch. Set `raw=true` to return raw data and correct offsets.
"""
function array(f::ROOTFile, path::AbstractString; raw=false)
    return array(f::ROOTFile, f[path]; raw=raw)
end

function array(f::ROOTFile, branch; raw=false)
    ismissing(branch) && error("No branch found at $path")
    (!raw && length(branch.fLeaves.elements) > 1) && error(
        "Branches with multiple leaves are not supported yet. Try reading with `array(...; raw=true)`.",
    )

    rawdata, rawoffsets = readbranchraw(f, branch)
    if raw
        return rawdata, rawoffsets
    end
    T, J = auto_T_JaggT(f, branch; customstructs=f.customstructs)
    return interped_data(rawdata, rawoffsets, T, J)
end

"""
    basketarray(f::ROOTFile, path::AbstractString, ith)
    basketarray(f::ROOTFile, branch::Union{TBranch, TBranchElement}, ith)
    basketarray(lb::LazyBranch, ith)

Reads actual data from ith basket of a branch. This function first calls [`readbasket`](@ref)
to obtain raw bytes and offsets of a basket, then calls [`auto_T_JaggT`](@ref) followed
by [`interped_data`](@ref) to translate raw bytes into actual data.
"""
function basketarray(f::ROOTFile, path::AbstractString, ithbasket)
    branch = f[path]
    ismissing(branch) && error("No branch found at $path")
    return basketarray(f, branch, ithbasket)
end

function rawbasketarray(f::ROOTFile, branch, ithbasket::Integer)
    length(branch.fLeaves.elements) > 1 && error(
        "Branches with multiple leaves are not supported yet. Try reading with `array(...; raw=true)`.",
    )

    if ithbasket != -1
        rawdata, rawoffsets = readbasket(f, branch, ithbasket)
    else
        # recovering a basket
        recovered_basket = branch.fBaskets.elements[end]
        rawdata, rawoffsets = recovered_basket.data, recovered_basket.offsets
    end
    return rawdata, rawoffsets
end

function basketarray(f::ROOTFile, branch, ithbasket::AbstractVector{<:Integer})
    tuples = [rawbasketarray(f, branch, i) for i in ithbasket]
    rawdata = reduce(vcat, first.(tuples))
    rawoffsets = reduce(vcat, last.(tuples))
    T, J = auto_T_JaggT(f, branch; customstructs=f.customstructs)
    return interped_data(rawdata, rawoffsets, T, J)
end


function basketarray(f::ROOTFile, branch, ithbasket::Integer)
    rawdata, rawoffsets = rawbasketarray(f, branch, ithbasket)
    T, J = auto_T_JaggT(f, branch; customstructs=f.customstructs)
    return interped_data(rawdata, rawoffsets, T, J)
end

"""
    basketarray_iter(f::ROOTFile, branch::Union{TBranch, TBranchElement})
    basketarray_iter(lb::LazyBranch)

Returns a `Base.Generator` yielding the output of `basketarray()` for all baskets.
"""
function basketarray_iter(f::ROOTFile, branch)
    return (basketarray(f, branch, i) for i in 1:numbaskets(branch))
end

# function barrior to make getting individual index faster
# TODO upstream some types into parametric types for Branch/BranchElement
"""
    LazyBranch(f::ROOTFile, branch)

Construct an accessor for a given branch such that `BA[idx]` and or `BA[1:20]` is
type-stable. And memory footprint is a single basket (<1MB usually). You can also
iterate or map over it. If you want a concrete `Vector`, simply `collect()` the
LazyBranch.

# Example
```julia
julia> rf = ROOTFile("./test/samples/tree_with_large_array.root");

julia> b = rf["t1/int32_array"];

julia> ab = UnROOT.LazyBranch(rf, b);

julia> for entry in ab
           @show entry
           break
       end
entry = 0

julia> ab[begin:end]
0
1
...
```
"""
mutable struct LazyBranch{T,J,B} <: AbstractVector{T}
    f::ROOTFile
    b::Union{TBranch,TBranchElement}
    L::Int64
    fEntry::Vector{Int64}
    buffer::Vector{B}
    thread_locks::Vector{ReentrantLock}
    buffer_range::Vector{UnitRange{Int64}}

    function LazyBranch(f::ROOTFile, b::Union{TBranch,TBranchElement})
        T, J = auto_T_JaggT(f, b; customstructs=f.customstructs)
        T = (T === Vector{Bool} ? BitVector : T)
        _buffer = T[]
        if J != Nojagg
            # if branch is jagged, fix the buffer and eltype according to what
            # VectorOfVectors would return in `getindex`
            _buffer = isbitstype(T) ? VectorOfVectors(T[], Int32[1]) : VectorOfVectors(T(), Int32[1])
            T = SubArray{eltype(T), 1, T, Tuple{UnitRange{Int64}}, true}
        end
        Nthreads = _maxthreadid()
        return new{T,J,typeof(_buffer)}(f, b, length(b),
                                        b.fBasketEntry,
                                        [_buffer for _ in 1:Nthreads],
                                        [ReentrantLock() for _ in 1:Nthreads],
                                        [0:-1 for _ in 1:Nthreads])
    end
end
LazyBranch(f::ROOTFile, s::AbstractString) = LazyBranch(f, f[s])
basketarray(lb::LazyBranch, ithbasket) = basketarray(lb.f, lb.b, ithbasket)
basketarray_iter(lb::LazyBranch) = basketarray_iter(lb.f, lb.b)

function Base.hash(lb::LazyBranch, h::UInt)
    h = hash(lb.f, h)
    h = hash(lb.b.fClassName, h)
    h = hash(lb.L, h)
    for br in lb.buffer_range
        h = hash(br, h)
    end
    return h
end
Base.size(ba::LazyBranch) = (ba.L,)
Base.length(ba::LazyBranch) = ba.L
Base.firstindex(ba::LazyBranch) = 1
Base.lastindex(ba::LazyBranch) = ba.L
Base.eltype(ba::LazyBranch{T,J,B}) where {T,J,B} = T


function Base.show(io::IO, lb::LazyBranch)
    summary(io, lb)
    println(io, ":")
    println(io, "  File: $(lb.f.filename)")
    println(io, "  Branch: $(lb.b.fName)")
    println(io, "  Description: $(lb.b.fTitle)")
    println(io, "  NumEntry: $(lb.L)")
    print(io, "  Entry Type: $(eltype(lb))")
    nothing
end

"""
    Base.getindex(ba::LazyBranch{T, J}, idx::Integer) where {T, J}

Get the `idx`-th element of a `LazyBranch`, starting at `1`. If `idx` is
within the range of `ba.buffer_range`, it will directly return from `ba.buffer`.
If not within buffer, it will fetch the correct basket by calling [`basketarray`](@ref)
and update buffer and buffer range accordingly.
"""

function Base.getindex(ba::LazyBranch{T,J,B}, idx::Integer) where {T,J,B}
    tid = Threads.threadid()
    tlock = @inbounds ba.thread_locks[tid]
    # index within the basket
    Base.@lock tlock begin
        br = @inbounds ba.buffer_range[tid]
        localidx = if idx ∉ br
            _localindex_newbasket!(ba, idx, tid)
        else
            idx - br.start + 1
        end
        return @inbounds ba.buffer[tid][localidx]
    end
end

function _localindex_newbasket!(ba::LazyBranch{T,J,B}, idx::Integer, tid::Int) where {T,J,B}
    seek_idx = findfirst(x -> x > (idx - 1), ba.fEntry) #support 1.0 syntax
    br = _get_buffer_range(ba, tid, seek_idx)
    ba.buffer_range[tid] = br
    return idx - br.start + 1
end

@inbounds function _get_buffer_range(ba::LazyBranch{T, J, B}, tid::Integer, seek_idx::Integer) where {T,J,B}
    seek_idx -= 1
    ba.buffer[tid] = basketarray(ba.f, ba.b, seek_idx)
    (ba.fEntry[seek_idx] + 1)::Int:(ba.fEntry[seek_idx + 1])::Int
end

function _get_buffer_range(ba::LazyBranch{T, J, B}, tid::Integer, ::Nothing) where {T,J,B}
    ba.buffer[tid] = basketarray(ba.f, ba.b, -1)  # -1 indicating recovered basket mechanics
    # FIXME: this range is probably wrong for jagged data with non-empty offsets
    (ba.b.fBasketEntry[end] + 1)::Int:ba.b.fEntries::Int
end

Base.IndexStyle(::Type{<:LazyBranch}) = IndexLinear()

function Base.iterate(ba::LazyBranch{T,J,B}, idx=1) where {T,J,B}
    idx > ba.L && return nothing
    return (ba[idx], idx + 1)
end

struct LazyEvent{T} <: Tables.AbstractRow
    tree::T
    idx::Int64
end
Base.propertynames(lt::LazyEvent) = propertynames(getfield(lt, :tree))
Tables.columnnames(row::LazyEvent) = propertynames(row)

Tables.getcolumn(row::LazyEvent, i::Int) = Tables.getcolumn(getfield(row, :tree), i)[getfield(row, :idx)]
Tables.getcolumn(row::LazyEvent, i::Symbol) = getproperty(row, i)

@inline function Base.getproperty(evt::LazyEvent, s::Symbol)
    @inbounds getproperty(Core.getfield(evt, :tree), s)[Core.getfield(evt, :idx)]
end
Base.Tuple(evt::LazyEvent) = Tuple(getproperty(evt, s) for s in propertynames(evt))
Base.NamedTuple(evt::LazyEvent) = NamedTuple{propertynames(evt)}(Tuple(evt))
Base.collect(evt::LazyEvent) = NamedTuple(evt)

function Base.show(io::IO, evt::LazyEvent)
    idx = Core.getfield(evt, :idx)
    fields = propertynames(Core.getfield(evt, :tree))
    nfields = length(fields)
    sfields = nfields < 20 ? ": $(fields)" : ""
    println(io, "UnROOT.LazyEvent at index $(idx) with $(nfields) columns:")
    show(io, collect(evt))
end

function Base.show(io::IO, ::Type{<:LazyEvent})
    print(io, "UnROOT.LazyEvent")
end

struct LazyTree{T<:NamedTuple} <: AbstractVector{LazyEvent{T}}
    treetable::T
end

Base.eachcol(t::LazyTree) = values(getfield(t, :treetable))
Tables.schema(t::LazyTree) = Tables.Schema(names(t), [eltype(col) for col in eachcol(t)])
Tables.partitions(t::LazyTree) = (t[r] for r in _clusterranges(t))

Tables.rowaccess(::LazyTree) = true
Tables.rows(t::LazyTree) = t

Tables.columnaccess(::LazyTree) = true
# The internal NamedTuple already satisfies the Tables interface
Tables.columns(t::LazyTree) = getfield(t, :treetable)

function LazyTree(path::String, x...; kwargs...)
    LazyTree(ROOTFile(path), x...; kwargs...)
end

Base.propertynames(lt::LazyTree) = propertynames(Tables.columns(lt))
Base.getproperty(lt::LazyTree, s::Symbol) = getproperty(Tables.columns(lt), s)

Base.broadcastable(lt::LazyTree) = lt
Base.IndexStyle(::Type{<:LazyTree}) = IndexLinear()
Base.getindex(lt::LazyTree, row::Int) = LazyEvent(Tables.columns(lt), row)
# kept lazy for broadcasting purpose
Base.getindex(lt::LazyTree, row::CartesianIndex{1}) = LazyEvent(Tables.columns(lt), row[1])
function Base.getindex(lt::LazyTree, rang)
    bnames = propertynames(lt)
    branches = map(b->getproperty(lt, b)[rang], bnames)
    return LazyTree(NamedTuple{bnames}(branches))
end

function Base.view(lt::LazyTree, idx...)
    return LazyTree(map(x->view(x, idx...), Tables.columns(lt)))
end

# a specific event
Base.getindex(lt::LazyTree, ::typeof(!), s) = lt[:, s]
Base.getindex(lt::LazyTree, ::Colon, s::Symbol) = getproperty(lt, s)
Base.getindex(lt::LazyTree, ::Colon, s::Int) = getproperty(lt, propertynames(lt)[s])
Base.getindex(lt::LazyTree, ::Colon, ss) = LazyTree(NamedTuple(propertynames(lt)[s]=>lt[:, s] for s in ss))
Base.getindex(lt::LazyTree, row::Int, col::Symbol) = lt[:, col][row]
Base.getindex(lt::LazyTree, rows::UnitRange, col::Symbol) = lt[:, col][rows]
Base.getindex(lt::LazyTree, row::Int, ::Colon) = lt[row]
Base.getindex(lt::LazyTree, row::AbstractVector, ::Colon) = lt[row]
Base.getindex(lt::LazyTree, ::Colon) = lt[1:end]

# allow enumerate() to be chunkable (eg with Threads.@threads)
Base.step(e::Iterators.Enumerate{LazyTree{T}}) where T = 1
Base.firstindex(e::Iterators.Enumerate{LazyTree{T}}) where T = firstindex(e.itr)
Base.lastindex(e::Iterators.Enumerate{LazyTree{T}}) where T = lastindex(e.itr)
Base.eachindex(e::Iterators.Enumerate{LazyTree{T}}) where T = eachindex(e.itr)
Base.getindex(e::Iterators.Enumerate{LazyTree{T}}, row::Int) where T = (row, LazyEvent(Tables.columns(e.itr), row))
# interfacing Table
Base.names(lt::LazyTree) = [String(x) for x in propertynames(lt)]
Base.length(lt::LazyTree) = length(first(Tables.columns(lt)))
Base.ndims(::Type{<:LazyTree}) = 1
Base.size(lt::LazyTree) = size(first(Tables.columns(lt))) # all column has the same size

"""
    chaintrees(ts)

Chain a collection of `LazyTree`s together to form a larger tree, every tree should
have identical branch names and types, we're not trying to re-implement SQL here.

## Example

```julia
julia> typeof(tree)
LazyTree with 1 branches:
a

julia> tree2 = UnROOT.chaintrees([tree,tree]);

julia> eltype(tree.a) == eltype(tree2.a)
true

julia> length(tree)
100

julia> length(tree2)
200

julia> eltype(tree)
UnROOT.LazyEvent{NamedTuple{(:a,), Tuple{LazyBranch{Int32, UnROOT.Nojagg, Vector{Int32}}}}}

julia> eltype(tree2)
UnROOT.LazyEvent{NamedTuple{(:a,), Tuple{SentinelArrays.ChainedVector{Int32, LazyBranch{Int32, UnROOT.Nojagg, Vector{Int32}}}}}}
```
"""
function chaintrees(ts)
    branch_names = propertynames(first(ts))
    res_branches = map(branch_names) do bname
        ChainedVector(getproperty.(ts, bname))
    end
    LazyTree(NamedTuple{branch_names}(res_branches))
end

Base.vcat(ts::LazyTree...) = chaintrees(collect(ts))
Base.reduce(::typeof(vcat), ts::AbstractVector{<:LazyTree}) = chaintrees(ts)

function getbranchnamesrecursive(obj)
    out = Vector{String}()
    for b in obj.fBranches.elements
        push!(out, b.fName)
        subs = getbranchnamesrecursive(b)
        !isempty(subs) && pop!(out)
        for subname in subs
            push!(out, "$(b.fName)/$(subname)")
        end
    end
    return out
end

"""
    LazyTree(f::ROOTFile, s::AbstractString, branch::Union{AbstractString, Regex})
    LazyTree(f::ROOTFile, s::AbstractString, branch::Vector{Union{AbstractString, Regex}})

Constructor for `LazyTree`, which is close to an `DataFrame` (interface wise),
and a lazy Table (speed wise). Looping over a `LazyTree` is fast and type
stable. Internally, `LazyTree` contains a typed table whose branch are [`LazyBranch`](@ref).
This means that at any given time only `N` baskets are cached, where `N` is the number of branches.

!!! note
    Accessing with `[start:stop]` will return a `LazyTree` with concrete internal table.

!!! warning
    Split branches are re-named, and the exact renaming may change. See 
    [Issue 156](https://github.com/JuliaHEP/UnROOT.jl/pull/156) for context.

# Example
```julia
julia> mytree = LazyTree(f, "Events", ["Electron_dxy", "nMuon", r"Muon_(pt|eta)\$"])
 Row │ Electron_dxy     nMuon   Muon_eta         Muon_pt
     │ Vector{Float32}  UInt32  Vector{Float32}  Vector{Float32}
─────┼───────────────────────────────────────────────────────────
 1   │ [0.000371]       0       []               []
 2   │ [-0.00982]       2       [0.53, 0.229]    [19.9, 15.3]
 3   │ []               0       []               []
 4   │ [-0.00157]       0       []               []
 ⋮   │     ⋮            ⋮             ⋮                ⋮
```
"""
function LazyTree(f::ROOTFile, s::AbstractString, branches; kwargs...)
    tree = f[s]
    if tree isa TTree
        return LazyTree(f, tree, s, branches; kwargs...)
    elseif tree isa RNTuple
        return LazyTree(tree, branches; kwargs...)
    end
    error("$s is not the name of a TTree or a RNTuple.")
end

function normalize_branchname(s::AbstractString)
    # split by `.` or `/`
    norm_name = s
    v = split(s, r"\.|\/")
    if length(v) >= 2 # only normalize name when branches are split
        head = v[1]
        tail = v[2:end]
        # remove duplicate info (only consecutive occurrences)
        idx = 1
        for e ∈ tail
            e != head && break
            idx += 1
        end
        elements = tail[idx:end]
        # remove known split branch information
        filter!(e -> e != "fCoordinates", elements)
        norm_name = join([head; elements], "_")
    end
    norm_name
end

"""
    function LazyTree(f::ROOTFile, tree::TTree, treepath, branches; sink = LazyTree)

Creates a lazy tree object of the selected branches only. `branches` is vector
of `String`, `Regex` or `Pair{Regex, SubstitutionString}`, where the first item
is the regex selector and the second item the rename pattern. An alternative 
container can be used by providing a sink function. The sink function must take as
argument an table with a Tables.jl interface. The table columns are filled with 
LazyBranch objects.

"""
function LazyTree(f::ROOTFile, tree::TTree, treepath, branches; sink = LazyTree)
    d = Dict{Symbol,LazyBranch}()
    _m(r::Regex) = Base.Fix1(occursin, r)
    all_bnames = getbranchnamesrecursive(tree)
    # rename_map = Dict{Regex, SubstitutionString{String}}()
    res_bnames = mapreduce(∪, branches) do b
        if b isa Regex
            [_b => normalize_branchname(_b) for _b ∈ filter(_m(b), all_bnames)]
        elseif b isa Pair{Regex, SubstitutionString{String}}
            [_b => replace(_b, first(b) => last(b)) for _b ∈ filter(_m(first.(b)), all_bnames)]
        elseif b isa String
            expand = any(n->startswith(n, "$b/$b"), all_bnames)
            expand ? [_b => normalize_branchname(_b) for _b ∈ filter(n->startswith(n, "$b/$b"), all_bnames)] : [b => normalize_branchname(b)]
        else
            error("branch selection must be string or regex")
        end
    end
    for (b, norm_name) in res_bnames
        d[Symbol(norm_name)] = LazyBranch(f, "$treepath/$b")
    end

    if sink == LazyTree
	return LazyTree(NamedTuple{Tuple(keys(d))}(values(d)))
    else
    	return sink(Tables.CopiedColumns(d))
    end
end

function LazyTree(f::ROOTFile, s::AbstractString; kwargs...)
    return LazyTree(f, s, keys(f[s]); kwargs...)
end

function LazyTree(f::ROOTFile, s::AbstractString, branch::Union{AbstractString,Regex}; kwargs...)
    return LazyTree(f, s, [branch]; kwargs...)
end

function Base.iterate(tree::T, idx=1) where {T<:LazyTree}
    idx > length(tree) && return nothing
    return LazyEvent(Tables.columns(tree), idx), idx + 1
end

function Base.getindex(ba::LazyBranch{T,J,B}, range::UnitRange) where {T,J,B}
    ib1 = findfirst(x -> x > (first(range) - 1), ba.fEntry)
    ib2 = findfirst(x -> x > (last(range) - 1), ba.fEntry) 
    if isnothing(ib1) #Check if we are completely on the recovered basket
        offset = ba.b.fBasketEntry[end]
        iths = [-1] # use magic number -1 as address for recovered basket only
    elseif isnothing(ib2) # Check if we partially on the recovered basket
        offset = ba.fEntry[ib1-1]
        iths = vcat(collect(ib1-1:length(ba.fEntry)-1), -1) # append magic number -1 for recovered basket at the end of the basket address range
    else # Keep everything as it was
        offset = ba.fEntry[ib1-1]
        iths = ib1-1:ib2-1
    end
    range = (first(range)-offset):(last(range)-offset)
    return basketarray(ba, iths)[range]
end

_clusterranges(t::LazyTree) = _clusterranges([getproperty(t,p) for p in propertynames(t)])
function _clusterranges(lbs::AbstractVector{<:LazyBranch})
    basketentries = [lb.b.fBasketEntry[1:numbaskets(lb.b)+1] for lb in lbs]
    common = mapreduce(Set, ∩, basketentries) |> collect |> sort
    return [common[i]+1:common[i+1] for i in 1:length(common)-1]
end
_clusterbytes(t::LazyTree; kw...) = _clusterbytes([getproperty(t,p) for p in propertynames(t)]; kw...)
function _clusterbytes(lbs::AbstractVector{<:LazyBranch}; compressed=false)
    basketentries = [lb.b.fBasketEntry[1:numbaskets(lb.b)+1] for lb in lbs]
    common = mapreduce(Set, ∩, basketentries) |> collect |> sort
    bytes = zeros(Float64, length(common)-1)
    for lb in lbs
        b = lb.b
        finflate = compressed ? 1.0 : b.fTotBytes/b.fZipBytes
        entries = b.fBasketEntry[1:numbaskets(b)+1]
        basketbytes = b.fBasketBytes[1:numbaskets(b)+1] * finflate
        iclusters = searchsortedlast.(Ref(common), entries[1:end-1])
        pairs = zip(iclusters, basketbytes)
        sumbytes = [sum(last.(g)) for g in groupby(first, pairs)]
        bytes .+= sumbytes
    end
    return bytes
end
