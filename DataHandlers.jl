using CSV, DataFrames
# using Gadfly

# TODO Figure Julia Documentation and reformat

# TODO Make functional
"Creates copy of `DataFrame` with empty columns."
blank(df::DataFrame)::DataFrame = (_df=DataFrame(); foreach(x -> _df[x]=[], names(df)); _df)

# TODO Make functional
"Creates copy of `DataFrame` with empty columns plus an index column."
blanki(df::DataFrame)::DataFrame = (_df=DataFrame(i=[]); foreach(x -> _df[x]=[], names(df)); _df)

"""
Concatenate array of `DataFrame`s, adding index column `i` to each.

`NOTE` Implicit assumption is made that all `DataFrame`s in array have identical column names.
"""
concati(d::Array{DataFrame})::DataFrame = (
        reduce((a, c) ->
            (i=a[:i]+1, df=append!(a[:df], indexdf(c; i=a[:i]+1)))
            ,d; init=(i=0, df=blanki(d |> first)))
    )[:df]

"Create `n`-length array of `c`."
constant(c, n::Integer) = repeat([c]; outer=n)

"Create array of `(colname, [col])` from `DataFrame`."
# !TS
destructure(d::DataFrame)::Array{Tuple{Symbol, AbstractArray}} = map(identity, zip(names(d), DataFrames.columns(d)))

# TODO Make functional
""
indexdf(df::DataFrame; f::Function=constant, i::Integer=0)::DataFrame = (_ds=destructure(df); _df=DataFrame(i=f(i, first(_ds)[2] |> length)); foreach(x -> _df[x[1]]=x[2], _ds); _df)

"Load `*.csv` in `p` into `DataFrame`s."
# !TS
ldc(p::String)::Array{NamedTuple{(:name, :df), Tuple{String, DataFrame}}} = p |> lsc .|> x -> (name=(x |> splitp |> namefromend), df=CSV.read(x))

# loadcsvd(dir::String)::Lazy.LazyList = @lazy @>> lsdir(dir) map(x -> @> "$dir/$x" loadcsv) flatten
# use `walkdir`
# "List all `*.csv` in tree beneath `p`."
# ldcd(p::String)::Array{String} = 

"List `*.csv` in `a`."
lsc(a::Array{String})::Array{String} = filter(y -> occursin(r".csv", y), a)

"List `*.csv` in `p`."
lsc(p::String)::Array{String} = p |> readjp |> lsc

"List directories in `p`."
lsd(p::String)::Array{String} = p |> readjp |> x -> filter(isdir, x)

"Convert `mm:ss` to `AbstractFloat` of seconds."
mmssToFloat(v::Union{Missing, String})::Union{AbstractFloat, Missing} = v |> typeof == Missing ? missing : split(v, ":") |> x -> [parse(Int, y) for y in x] |> x -> (60*x[1] + x[2]) |> float

"Create name from last two values in an array."
namefromend(a::Array)::String = "$(a[end-1])-$(a[end])"

"Execute `zerobase` on array of `DataFrame`s."
rebasez(dfs::Array{NamedTuple{(:name, :df), Tuple{String, DataFrame}}}, k::Symbol = :t)::Array{NamedTuple{(:name, :df), Tuple{String, DataFrame}}} = dfs .|> x -> rebasez(x, k)

"Execute `zerobase` on `DataFrame` column."
rebasez(nt::NamedTuple{(:name, :df), Tuple{String, DataFrame}}, k::Symbol = :t)::NamedTuple{(:name, :df), Tuple{String, DataFrame}} = (nt[:df][k] = nt[:df][k] |> zerobase; nt)

"Reads `p`, joins with file/dir name."
readjp(p::String)::Array{String} = p |> readdir .|> x -> joinpath(p, x)

"Split `p` by `/`."
splitp(p::String)::Array{String} = p |> x -> split(x, "/")

"Rebase `a` such that `n = 0; a[n+1] = a[n+1] - a[1]`."
zerobase(a::Union{Array{<:AbstractFloat}, Array{<:Integer}, Array{Union{<:AbstractFloat, Missing}}, Array{Union{<:Integer, Missing}}})::Array{Union{AbstractFloat, Missing}} = a .|> x -> (x - first(a)) |> float

"Rebase `a` such that `n = 0; a[n+1] = a[n+1] - a[1]`. Values in seconds."
zerobase(a::Union{Array{String}, Array{Union{Missing, String}}})::Array{Union{AbstractFloat, Missing}} = a .|> x -> mmssToFloat(x) - mmssToFloat(a[1])