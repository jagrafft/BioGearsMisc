# DataHandlers.jl
# Functions which handle DataFrames are specific to a single project

using CSV, DataFrames, Gadfly, Lazy, Query

### Helper Functions ###
# drawplots :: Lazy.LazyList -> Function -> ()
drawplots(l::Lazy.LazyList, f::Function = plotjsdf) = @>> l map(x -> f(x)) foreach(x -> draw(PNG("$(x[1]).png", 9inch, 6inch), x[2]))

# lscsv :: String -> Lazy.LazyList
lscsv(p::String)::Lazy.LazyList = @lazy @>> readdir(p) filter(x -> contains(x, ".csv")) map(x -> "$p/$x")

# lsdir :: String -> Lazy.LazyList
# TODO refactor: requires "pure" directory of directories (`isdir(dir)` not consistent--may be linux-osx crossover)
lsdir(p::String)::Lazy.LazyList = @lazy @>> readdir(p) filter(x -> first(x) !== '.')

# loadcsv :: String -> Lazy.LazyList
loadcsv(dir::String)::Lazy.LazyList = @lazy @>> lscsv(dir) map(x -> @> x namefrompath tuple(CSV.read(x))) flatten

# loadcsvd :: String -> Lazy.LazyList
loadcsvd(dir::String)::Lazy.LazyList = @lazy @>> lsdir(dir) map(x -> @> "$dir/$x" loadcsv) flatten

# namefrompath :: String -> String
namefrompath(p::String)::String = @> p splitpath takelast(2) join("-")

# splitpath :: String -> Lazy.LazyList
splitpath(p::String)::Lazy.LazyList = @lazy @> p split("/")

### Visualize John Stuart RSI BioGears Data Sets ###
# TODO refactor (improve genericism)
# scalesp :: DataFrame -> DataFrame
function scalesp(df::DataFrame)::DataFrame
    @from i in df begin
        @select {Ts=i.s, SpO2=get(i.spO2)*100, MAP=i.map, HR=i.hr}
        @collect DataFrame
    end
end

# TODO refactor (improve genericism)
# lt90sp :: DataFrame -> DataFrame
function lt90sp(df::DataFrame)::DataFrame
    @from i in df begin
        @where i.SpO2 < 90
        @select {i.Ts, i.SpO2}
        @collect DataFrame
    end
end

# TODO refactor (improve genericism)
# plotjsdf :: Tuple{String, DataFrame} -> Tuple{String, Gadfly.Plot}
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