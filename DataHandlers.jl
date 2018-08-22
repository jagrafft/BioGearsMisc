using CSV, DataFrames
# using Gadfly

# TODO Figure Julia Documentation and reformat
"""
Concatenate array of `DataFrame`s, adding index column `i` to each.

`NOTE` Implicit assumption is made that all `DataFrame`s in array have identical column names.
"""
concati(d::Array{DataFrame})::DataFrame = (
        _df = DataFrame(i=[]);
        foreach(x -> _df[x] = [], d |> first |> names);
        reduce((a, c) -> (
            i = a[:i] + 1;
            ds = destructure(c);
            # df = XXX(ds);
            # create new function #
            df = DataFrame(i=constant(i, first(ds)[2] |> length));
            foreach(x -> df[x[1]]=x[2], ds);
            ##

            (i=i, df=append!(a[:df], df))
        ), d; init=(i=0, df=_df))
    )[:df]

"Create `n`-length array of `c`."
constant(c, n::Integer)::Array = repeat([c]; outer=[n])

"Create array of `(colname, [col])` from `DataFrame`."
destructure(d::DataFrame)::Array{Tuple{Symbol, AbstractArray}} = map(identity, zip(names(d), DataFrames.columns(d)))

"Load `*.csv` in `p` into `DataFrame`s."
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

##### REFACTOR #####
# "`drawplots :: Lazy.LazyList -> Function -> ()`"
# drawplots(l::Lazy.LazyList, f::Function = plotjsdf) = @>> l map(x -> f(x)) foreach(x -> draw(PNG("$(x[1]).png", 9inch, 6inch), x[2]))

##### TO BE DEPRECATED THEN RECREATED #####
# "scalesp :: DataFrame -> DataFrame"
# function scalesp(df::DataFrame)::DataFrame
#     @from i in df begin
#         @select {Ts=i.s, SpO2=get(i.spO2)*100, MAP=i.map, HR=i.hr}
#         @collect DataFrame
#     end
# end

# TODO refactor (improve genericism)
# "lt90sp :: DataFrame -> DataFrame"
# function lt90sp(df::DataFrame)::DataFrame
#     @from i in df begin
#         @where i.SpO2 < 90
#         @select {i.Ts, i.SpO2}
#         @collect DataFrame
#     end
# end

# TODO refactor (improve genericism)
# "plotjsdf :: Tuple{String, DataFrame} -> Tuple{String, Gadfly.Plot}"
# function plotjsdf(t::Tuple{String, DataFrame})::Tuple{String, Gadfly.Plot}
#     df = @> t[2] scalesp
#     lt = @> df lt90sp
#     tuple(
#         t[1],
#         plot(
#             layer(df, x=:Ts, y=:MAP, Geom.line, Theme(default_color=colorant"orange")),
#             layer(df, x=:Ts, y=:HR, Geom.line, Theme(default_color=colorant"green")),
#             layer(lt, x=:Ts, y=:SpO2, Geom.line, Theme(default_color=colorant"red")),
#             layer(df, x=:Ts, y=:SpO2, Geom.line, Theme(default_color=colorant"deepskyblue")),
#             Guide.xlabel("Time (seconds)"),
#             Guide.ylabel(""),
#             Guide.title("$(t[1])"),
#             Guide.manual_color_key("Legend", ["MAP", "HR", "SpO2 ≥ 90%"], ["orange", "green", "deepskyblue"])
#         )
#     )
# end