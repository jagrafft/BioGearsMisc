using CSV, DataFrames, JuliaDB, HypothesisTests, OnlineStats, Plots, StatsBase, StatsPlots, GR; gr(dpi=400)

gi = loadtable("data/Milestones/2017-2018/GIBleed-num.csv");
ob = loadtable("data/Milestones/2017-2018/OBD-num.csv");

sample_size = 375
# samplings = 15

## Theta
gi_bool_feats = map(x -> maximum(x[1]) < 3 ? x[2] : missing, columns(select(gi, Between(8,38))) |> x -> zip(values(x), keys(x))) |> skipmissing |> collect
ob_bool_feats = map(x -> maximum(x[1]) < 3 ? x[2] : missing, columns(select(ob, Between(8,39))) |> x -> zip(values(x), keys(x))) |> skipmissing |> collect

gi_th = map(x -> (l=length(x[1]); c=count(i -> i == 1, x[1]); NamedTuple{(:feature,:N,:len,:θ)}((x[2], c, l, round(c/l, digits=2)))), gi_bool_feats .|> x -> (select(gi, x), x)) |> table
ob_th = map(x -> (l=length(x[1]); c=count(i -> i == 1, x[1]); NamedTuple{(:feature,:N,:len,:θ)}((x[2], c, l, round(c/l, digits=2)))), ob_bool_feats .|> x -> (select(ob, x), x)) |> table

# Statistics
## Descriptive
gi_desc = map(x -> NamedTuple{(:id,:len,:min,:max,:μ,:σ,:cov,:skewness,:kurtosis)}(tuple(x[2], round.([length(x[1]), minimum(x[1]), maximum(x[1]), mean(x[1]), std(x[1]), OnlineStats.cov(x[1]), skewness(x[1]), kurtosis(x[1])], digits=2)...)), columns(select(gi, Between(8,38))) |> x -> zip(values(x), keys(x))) |> table

ob_desc = map(x -> NamedTuple{(:id,:len,:min,:max,:μ,:σ,:cov,:skewness,:kurtosis)}(tuple(x[2], round.([length(x[1]), minimum(x[1]), maximum(x[1]), mean(x[1]), std(x[1]), OnlineStats.cov(x[1]), skewness(x[1]), kurtosis(x[1])], digits=2)...)), columns(select(ob, Between(8,39))) |> x -> zip(values(x), keys(x))) |> table

## Unequal variance T-tests
gi_ost = ((reduce((a,c) -> (push!(a[1], round.([v for v in map(x -> UnequalVarianceTTest(select(gi, c), select(gi, x)) |> pvalue, a[2])], digits=2)); a[2] = a[2][2:end]; a), colnames(gi)[8:38], init=[[], colnames(gi)[8:38]])[1] .|> x -> vcat([Missing for z in 1:1:(31-length(x))], x)) |> m -> zip(colnames(gi)[8:38], m) .|> x -> NamedTuple{tuple(:features, colnames(gi)[8:38]...)}(tuple([x[1], x[2]...]...))) |> table

ob_ost = ((reduce((a,c) -> (push!(a[1], round.([v for v in map(x -> UnequalVarianceTTest(select(ob, c), select(ob, x)) |> pvalue, a[2])], digits=2)); a[2] = a[2][2:end]; a), colnames(ob)[8:39], init=[[], colnames(ob)[8:39]])[1] .|> x -> vcat([Missing for z in 1:1:(32-length(x))], x)) |> m -> zip(colnames(ob)[8:39], m) .|> x -> NamedTuple{tuple(:features, colnames(gi)[8:39]...)}(tuple([x[1], x[2]...]...))) |> table

feat_ost = [x for x in reduce((a,c) -> (push!(a[1], (i=a[2], feature=c, pvalue=(([gi, ob] .|> x -> select(x, c)) |> x -> round(UnequalVarianceTTest(x[1], x[2]) |> pvalue, digits=2)))); a[2] = a[2] + 1; a), intersect(colnames(gi), colnames(ob))[8:34], init=[[], 1])[1]] |> table

## Covarience
gi_cov = ((reduce((a,c) -> (push!(a[1], round.([v for v in map(x -> OnlineStats.cov(select(gi, c), select(gi, x)), a[2])], digits=2)); a[2] = a[2][2:end]; a), colnames(gi)[8:38], init=[[], colnames(gi)[8:38]])[1] .|> x -> vcat([Missing for z in 1:1:(31-length(x))], x)) |> m -> zip(colnames(gi)[8:38], m) .|> x -> NamedTuple{tuple(:features, colnames(gi)[8:38]...)}(tuple([x[1], x[2]...]...))) |> table

ob_cov = ((reduce((a,c) -> (push!(a[1], round.([v for v in map(x -> OnlineStats.cov(select(ob, c), select(ob, x)), a[2])], digits=2)); a[2] = a[2][2:end]; a), colnames(ob)[8:39], init=[[], colnames(ob)[8:39]])[1] .|> x -> vcat([Missing for z in 1:1:(32-length(x))], x)) |> m -> zip(colnames(ob)[8:39], m) .|> x -> NamedTuple{tuple(:features, colnames(gi)[8:39]...)}(tuple([x[1], x[2]...]...))) |> table

feat_cov = [x for x in reduce((a,c) -> (push!(a[1], (i=a[2], N=sample_size, feature=c, cov=([gi, ob] .|> x -> select(x, c) |> x -> StatsBase.sample(x, sample_size, replace=false)) |> x -> round(OnlineStats.cov(x[1], x[2]), digits=2))); a[2] = a[2] + 1; a), intersect(colnames(gi), colnames(ob))[8:34], init=[[], 1])[1]] |> table

## Write CSV
[("Theta_GIBleed.csv", gi_th), ("Theta_OBD.csv", ob_th), ("DescriptiveStats_GIBleed.csv", gi_desc), ("DescriptiveStats_OBD.csv", ob_desc), ("UneqVarTTest_GIBleed.csv", gi_ost), ("UneqVarTTest_OBD.csv", ob_ost), ("UneqVarTTest_by_common_feature.csv", feat_ost), ("Covariance_GIBleed.csv", gi_cov), ("Covariance_OBD.csv", ob_cov), ("Covariance_by_common_feature.csv", feat_cov)] .|> x -> CSV.write(x...)

# Plots
gi_feats_names = [String(x) for x in colnames(select(gi, Between(8,38)))]
ob_feats_names = [String(x) for x in colnames(select(ob, Between(8,39)))]

## Histograms
### GI
png((@df gi StatsPlots.histogram(cols(8:16), legend=false, titlefont=font(8), xticks=[1,2,3], layout=9, label="", bins=:scott, title=reshape(gi_feats_names[1:9],1,9))), "GI_Bleed_1_hist.png")
png((@df gi StatsPlots.histogram(cols(17:25), legend=false, titlefont=font(8), xticks=[1,2,3], layout=9, label="", bins=:scott, title=reshape(gi_feats_names[10:18],1,9))), "GI_Bleed_2_hist.png")
png((@df gi StatsPlots.histogram(cols(26:34), legend=false, titlefont=font(8), xticks=[1,2,3], layout=9, label="", bins=:scott, title=reshape(gi_feats_names[19:27],1,9))), "GI_Bleed_3_hist.png")
png((@df gi StatsPlots.histogram(cols(35:38), legend=false, titlefont=font(8), xticks=[1,2,3], layout=4, label="", bins=:scott, title=reshape(gi_feats_names[28:31],1,4))), "GI_Bleed_4_hist.png")

### OBD
png((@df ob StatsPlots.histogram(cols(8:16), legend=false, titlefont=font(8), xticks=[1,2,3], layout=9, label="", bins=:scott, title=reshape(ob_feats_names[1:9],1,9))), "OBD_1_hist.png")
png((@df ob StatsPlots.histogram(cols(17:25), legend=false, titlefont=font(8), xticks=[1,2,3], layout=9, label="", bins=:scott, title=reshape(ob_feats_names[10:18],1,9))), "OBD_2_hist.png")
png((@df ob StatsPlots.histogram(cols(26:34), legend=false, titlefont=font(8), xticks=[1,2,3], layout=9, label="", bins=:scott, title=reshape(ob_feats_names[19:27],1,9))), "OBD_3_hist.png")
png((@df ob StatsPlots.histogram(cols(35:39), legend=false, titlefont=font(8), xticks=[1,2,3], layout=5, label="", bins=:scott, title=reshape(ob_feats_names[28:32],1,5))), "OBD_4_hist.png")

## Density Plots
### GI
# png((@df gi StatsPlots.density(cols(8:16), legend=false, titlefont=font(8), xticks=[1,2,3], layout=9, label="", title=reshape(gi_feats_names[1:9],1,9))), "GI_Bleed_1_den.png")
# png((@df gi StatsPlots.density(cols(17:25), legend=false, titlefont=font(8), xticks=[1,2,3], layout=9, label="", title=reshape(gi_feats_names[10:18],1,9))), "GI_Bleed_2_den.png")
# png((@df gi StatsPlots.density(cols(26:34), legend=false, titlefont=font(8), xticks=[1,2,3], layout=9, label="", title=reshape(gi_feats_names[19:27],1,9))), "GI_Bleed_3_den.png")
# png((@df gi StatsPlots.density(cols(35:38), legend=false, titlefont=font(8), xticks=[1,2,3], layout=4, label="", title=reshape(gi_feats_names[28:31],1,4))), "GI_Bleed_4_den.png")

### OBD
# png((@df ob StatsPlots.density(cols(8:16), legend=false, titlefont=font(8), xticks=[1,2,3], layout=9, label="", title=reshape(ob_feats_names[1:9],1,9))), "OBD_1_den.png")
# png((@df ob StatsPlots.density(cols(17:25), legend=false, titlefont=font(8), xticks=[1,2,3], layout=9, label="", title=reshape(ob_feats_names[10:18],1,9))), "OBD_2_den.png")
# png((@df ob StatsPlots.density(cols(26:34), legend=false, titlefont=font(8), xticks=[1,2,3], layout=9, label="", title=reshape(ob_feats_names[19:27],1,9))), "OBD_3_den.png")
# png((@df ob StatsPlots.density(cols(35:39), legend=false, titlefont=font(8), xticks=[1,2,3], layout=5, label="", title=reshape(ob_feats_names[28:32],1,5))), "OBD_4_den.png")