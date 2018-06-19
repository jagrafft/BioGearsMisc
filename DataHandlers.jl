# DataHandlers.jl
# Functions which handle DataFrames are specific to a single project

using CSV, DataFrames, Gadfly, Lazy, Query
# using DataStructures: Trie
# using LightXML

### Helper Functions ###
# loadcsv :: String -> Lazy.LazyList{(String, DataFrame)}
loadcsv(dir::String)::Lazy.LazyList = @lazy @>> lscsv(dir) map(x -> (convert(String, split(x, "/")[end]), CSV.read(x))) reduce(vcat,[])

# loadcsvd :: String -> Lazy.LazyList{(String, DataFrame)}
loadcsvd(dir::String)::Lazy.LazyList = @lazy @>> lsdir(dir) map(x -> lscsv("$dir/$x")) map(x -> map(y -> (convert(String, "$(split(y, "/")[end-1])-$(split(y, "/")[end])"), CSV.read(y)), x)) reduce(*)

# lscsv :: String -> Lazy.LazyList{String}
lscsv(p::String)::Lazy.LazyList = @lazy @>> readdir(p) filter(x -> contains(x, ".csv")) map(x -> "$p/$x")

# TODO refactor: requires "pure" directory of directories (`isdir(dir)` not consistent--may be linux-osx crossover)
# lsdir :: String -> Lazy.LazyList{String}
lsdir(p::String)::Lazy.LazyList = @lazy @>> readdir(p) filter(x -> first(x) !== '.')

# drawplots :: Lazy.LazyList -> Function -> ()
drawplots(l::Lazy.LazyList, f::Function) = @>> l map(x -> f(x)) foreach(x -> draw(PNG("$(x[1]).png", 9inch, 6inch), x[2]))

### Generate BioGears XML File ###

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
# splt90 :: DataFrame -> DataFrame
function lt90sp(df::DataFrame)::DataFrame
    @from i in df begin
        @where i.SpO2 < 90
        @select {i.Ts, i.SpO2}
        @collect DataFrame
    end
end

# TODO refactor (improve genericism)
# bgplot :: (String, DataFrame) -> (String, Gadfly.Plot)
function plotdf(t::Tuple{String, DataFrame})::Tuple{String, Gadfly.Plot}
    df = @> t[2] scalesp
    (
        t[1],
        plot(df,
            x=:Ts,
            y=Col.value(:SpO2, :MAP, :HR),
            color=Col.index(:SpO2, :MAP, :HR),
            Geom.line,
            Guide.xlabel("Time (seconds)"),
            Guide.ylabel(""),
            Guide.title("$(t[1])")
        )
    )
end

# TODO refactor (improve genericism)
# hlplot :: (String, DataFrame) -> (String, Gadfly.Plot)
function plotsp(t::Tuple{String, DataFrame})::Tuple{String, Gadfly.Plot}
    df = @> t[2] scalesp
    lt = @> df splt90
    (
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