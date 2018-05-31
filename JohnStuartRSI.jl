using CSV, DataFrames, Gadfly, Lazy, LightXML, Query
using DataStructures: Trie

# Punch List #
# - Pyshcomotor Event Log -> BioGears XML
# - `lsdir` requires "pure" directory of directories (`isdir(dir)` not consistent--may be linux-osx crossover)
# - 

# loadcsv :: String -> [(String, DataFrame)]
loadcsv(dir) = @>> lscsv(dir) map(x -> (split(x,"/")[end],CSV.read(x))) reduce(vcat,[]);

# loadcsvdirs :: String -> [(String, DataFrame)]
loadcsvdirs(dir) = @>> lsdir(dir) map(x -> lscsv("$dir/$x")) map(x -> map(y -> ("$(split(y,"/")[end-1])-$(split(y,"/")[end])",CSV.read(y)), x)) reduce(vcat,[]);

# lscsv :: String -> [String]
lscsv(p) = @>> readdir(p) filter(x -> contains(x, ".csv")) map(x -> "$p/$x");

# lsdir :: String -> [String]
lsdir(p) = @>> readdir(p) filter(x -> first(x) !== '.');

# Event Log -> BioGears Scenario #


# BioGears #
# bgformat :: DataFrame -> DataFrame
bgformat(df) = @from i in df begin @select {Ts=i.s, SpO2=get(i.spO2)*100, MAP=i.map, HR=i.hr} @collect DataFrame end;

# bgplot :: (String, DataFrame) -> (String, Gadfly.Plot)
bgplot(tup) = (tup[1], plot(tup[2], x=:Ts, y=Col.value(:SpO2, :MAP, :HR), color=Col.index(:SpO2, :MAP, :HR), Geom.line, Guide.xlabel("Time (seconds)"), Guide.ylabel(""), Guide.title("$(tup[1])")));

# bgplots :: String -> 
bgplots(dir) = @>> loadcsv(dir) map(x -> (x[1],bgformat(x[2]))) map(x -> bgplot(x)) foreach(x -> draw(PNG("$(x[1]).png",9inch,6inch), x[2]));

# bgplotsdir :: String ->
bgplotsdirs(dir) = @>> loadcsvdirs(dir) map(x -> (x[1],bgformat(x[2]))) map(x -> bgplot(x)) foreach(x -> draw(PNG("$(x[1]).png",9inch,6inch), x[2]));