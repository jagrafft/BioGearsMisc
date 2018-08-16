using CSV, DataFrames
# using Gadfly

"Load `*.csv` in `p` into `DataFrame`s."
ldc(p::String)::Array{NamedTuple{(:name, :df), Tuple{String, DataFrame}}} = p |> lsc .|> x -> (name=namefromend(splitp(x)), df=CSV.read(x))

""
# ldcd()

"List `*.csv` in `p`."
lsc(p::String)::Array{String} = p |> rjp |> x -> filter(y -> occursin(r".csv", y), x)

"List directories in `p`."
lsd(p::String)::Array{String} = p |> rjp |> x -> filter(isdir, x)

"Convert `mm:ss` to `AbstractFloat` of seconds."
mmssToFloat(v::String)::AbstractFloat = split(v, ":") |> x -> [parse(Int, y) for y in x] |> x -> (60*x[1] + x[2]) |> x -> float(x)

"Create name from last two values in an array."
namefromend(a::Array)::String = "$(a[end-1])-$(a[end])"

"Reads `p`, joins with file/dir name."
rjp(p::String)::Array{String} = p |> readdir .|> x -> joinpath(p, x)

"Split `p` by `/`."
splitp(p::String)::Array{String} = p |> x -> split(x, "/")

"Rebase `a` such that `n = 0; a[n+1] = a[n+1] - a[1]`."
zerobase(a::Union{Array{<:AbstractFloat}, Array{<:Integer}})::Array{<:AbstractFloat} = a .|> x -> (x - a[1]) |> x -> float(x)

"Rebase `a` such that `n = 0; a[n+1] = a[n+1] - a[1]`. Values in seconds."
zerobase(a::Array{String})::Array{AbstractFloat} = a .|> x -> mmssToFloat(x) - mmssToFloat(a[1])

##### REFACTOR #####
# "`drawplots :: Lazy.LazyList -> Function -> ()`"
""
drawplots(l::Lazy.LazyList, f::Function = plotjsdf) = @>> l map(x -> f(x)) foreach(x -> draw(PNG("$(x[1]).png", 9inch, 6inch), x[2]))

"Load all `*.csv` in ?...?, return as `Lazy.List{Tuple(:name, :df)}`."
loadcsvd(dir::String)::Lazy.LazyList = @lazy @>> lsdir(dir) map(x -> @> "$dir/$x" loadcsv) flatten

##### TO BE DEPRECATED #####
"scalesp :: DataFrame -> DataFrame"
function scalesp(df::DataFrame)::DataFrame
    @from i in df begin
        @select {Ts=i.s, SpO2=get(i.spO2)*100, MAP=i.map, HR=i.hr}
        @collect DataFrame
    end
end

# TODO refactor (improve genericism)
"lt90sp :: DataFrame -> DataFrame"
function lt90sp(df::DataFrame)::DataFrame
    @from i in df begin
        @where i.SpO2 < 90
        @select {i.Ts, i.SpO2}
        @collect DataFrame
    end
end

# TODO refactor (improve genericism)
"plotjsdf :: Tuple{String, DataFrame} -> Tuple{String, Gadfly.Plot}"
function plotjsdf(t::Tuple{String, DataFrame})::Tuple{String, Gadfly.Plot}
    df = @> t[2] scalesp
    lt = @> df lt90sp
    tuple(
        t[1],
        plot(
            layer(df, x=:Ts, y=:MAP, Geom.line, Theme(default_color=colorant"orange")),
            layer(df, x=:Ts, y=:HR, Geom.line, Theme(default_color=colorant"green")),
            layer(lt, x=:Ts, y=:SpO2, Geom.line, Theme(default_color=colorant"red")),
            layer(df, x=:Ts, y=:SpO2, Geom.line, Theme(default_color=colorant"deepskyblue")),
            Guide.xlabel("Time (seconds)"),
            Guide.ylabel(""),
            Guide.title("$(t[1])"),
            Guide.manual_color_key("Legend", ["MAP", "HR", "SpO2 ≥ 90%"], ["orange", "green", "deepskyblue"])
        )
    )
end