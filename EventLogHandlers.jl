using CSV, DataFrames, HypothesisTests, KernelDensity, MultivariateStats, ORCA, Plots, StatsBase
# Clustering,Distributions,StatsModels,MLBase,Distances,TimeSeries
include("./DataHandlers.jl")

p = "data/JohnStuartRSI/psychomotor/";
df = CSV.read("$p/001-015.csv");
dfs = "$p/seconds" |> ldc;

# Add event:code column to df
df[:ev_code] = join.(zip(df[:event], df[:code]), ":");

# Take mean of :t in all dataframes in `dfs`
dfsmeans = dfs .|> x -> (x.name[9:11], StatsBase.mean(x.df.t));

# Extract start/stop pairs (in a DataFrame) to dictionary
_d=Dict(); ["eti:start", "eti:stop", "laryngoscopy:start", "laryngoscopy:stop"] .|> ev -> (_df = DataFrame(); tuplesbykey(df, :ev_code, [:i, :t], [ev]) |> y -> (keys(y[1].vals) .|> z -> _df[z] = (y .|> v -> v.vals[z])); _d[ev] = _df; _d);

# Makes "eti:start", "eti:stop" equal lengths
# append!(_d["eti:stop"], DataFrame(i=[15], t=[190.]))

keys(_d) .|> k -> (dfsmeans .|> x -> ("$(x[1])$(k)", HypothesisTests.OneSampleTTest(_d[k].t, x[2])))

tstatHead = ["set","param","h0","point_est","95CI","p","accept","n","t-stat","df","stderr"];
tTable(t::Vector{Tuple{String, OneSampleTTest}})::String = reduce((a,c) -> (param=HypothesisTests.population_param_of_interest(c[2]); p=pvalue(c[2]); "$a\n$(join([c[1], param[1], param[2], param[3], "\"$(map(x -> round.(x, digits=4, base=10), StatsBase.confint(c[2])))\"", p, p > 0.05 ? "true" : "false", c[2].n, c[2].t, c[2].df, c[2].stderr], ","))"), t; init=join(tstatHead,","));