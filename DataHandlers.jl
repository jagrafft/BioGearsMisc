# using CSV, Gadfly, Lazy

"Convert `mm:ss` to `AbstractFloat` of seconds."
mmssToFloat(v::String)::AbstractFloat = split(v, ":") |> x -> [parse(Int, y) for y in x] |> x -> (60*x[1] + x[2]) |> x -> float(x)

"Rebase `a` such that `n = 0; a[n+1] = a[n+1] - a[1]`."
zerobase(a::Union{Array{<:AbstractFloat}, Array{<:Integer}})::Array{<:AbstractFloat} = a .|> x -> (x - a[1]) |> x -> float(x)

"Rebase `a` such that `n = 0; a[n+1] = a[n+1] - a[1]`. Values in seconds."
zerobase(a::Array{String})::Array{AbstractFloat} = a .|> x -> mmssToFloat(x) - mmssToFloat(a[1])

##### REFACTOR #####
# "`drawplots :: Lazy.LazyList -> Function -> ()`"
""
drawplots(l::Lazy.LazyList, f::Function = plotjsdf) = @>> l map(x -> f(x)) foreach(x -> draw(PNG("$(x[1]).png", 9inch, 6inch), x[2]))

# "`lscsv :: String -> Lazy.LazyList`"
""
lscsv(p::String)::Lazy.LazyList = @lazy @>> readdir(p) filter(x -> contains(x, ".csv")) map(x -> "$p/$x")

# "`lsdir :: String -> Lazy.LazyList`"
""
# TODO refactor: requires "pure" directory of directories (`isdir(dir)` not consistent--may be linux-osx crossover)
lsdir(p::String)::Lazy.LazyList = @lazy @>> readdir(p) filter(x -> first(x) !== '.')

"Load all `*.csv` in a single directory via `CSV.read`, return as `Lazy.List{Tuple(:name, :df)}`."
loadcsv(dir::String)::Lazy.LazyList = @lazy @>> lscsv(dir) map(x -> tuple(name=namefrompath(x), df=CSV.read(x))) flatten

"Load all `*.csv` in ?...?, return as `Lazy.List{Tuple(:name, :df)}`."
loadcsvd(dir::String)::Lazy.LazyList = @lazy @>> lsdir(dir) map(x -> @> "$dir/$x" loadcsv) flatten

# "`namefrompath :: String -> String`"
""
namefrompath(p::String)::String = @> p splitpath takelast(2) join("-")

# "`splitpath :: String -> Lazy.LazyList`"
""
splitpath(p::String)::Lazy.LazyList = @lazy @> p split("/")

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