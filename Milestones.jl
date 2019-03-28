using CSV, DataFrames, JuliaDB, HypothesisTests, OnlineStats, Plots, StatsBase, StatsPlots, GR; gr(dpi=400)

gi = loadtable("data/Milestones/2017-2018/GIB-num.csv");
ob = loadtable("data/Milestones/2017-2018/OBD-num.csv");

sample_size = 375
# samplings = 15

# Statistics
## Descriptive
gi_summary = map(x -> NamedTuple{(:id,:len,:min,:max,:μ,:σ,:cov,:skewness,:kurtosis)}(tuple(x[2], round.([length(x[1]), minimum(x[1]), maximum(x[1]), mean(x[1]), std(x[1]), OnlineStats.cov(x[1]), skewness(x[1]), kurtosis(x[1])], digits=2)...)), columns(select(gi, Between(8,38))) |> x -> zip(values(x), keys(x))) |> table

ob_summary = map(x -> NamedTuple{(:id,:len,:min,:max,:μ,:σ,:cov,:skewness,:kurtosis)}(tuple(x[2], round.([length(x[1]), minimum(x[1]), maximum(x[1]), mean(x[1]), std(x[1]), OnlineStats.cov(x[1]), skewness(x[1]), kurtosis(x[1])], digits=2)...)), columns(select(ob, Between(8,39))) |> x -> zip(values(x), keys(x))) |> table

## Pearson's r
gi_pearsons = ((reduce((a,c) -> (push!(a[1], round.([v for v in map(x -> OnlineStats.cor(select(gi, c), select(gi, x)), a[2])], digits=2)); a[2] = a[2][2:end]; a), colnames(gi)[8:38], init=[[], colnames(gi)[8:38]])[1] .|> x -> vcat([Missing for z in 1:1:(31-length(x))], x)) |> m -> zip(colnames(gi)[8:38], m) .|> x -> NamedTuple{tuple(:features, colnames(gi)[8:38]...)}(tuple([x[1], x[2]...]...))) |> table

ob_pearsons = ((reduce((a,c) -> (push!(a[1], round.([v for v in map(x -> OnlineStats.cor(select(ob, c), select(ob, x)), a[2])], digits=2)); a[2] = a[2][2:end]; a), colnames(ob)[8:39], init=[[], colnames(ob)[8:39]])[1] .|> x -> vcat([Missing for z in 1:1:(32-length(x))], x)) |> m -> zip(colnames(ob)[8:39], m) .|> x -> NamedTuple{tuple(:features, colnames(ob)[8:39]...)}(tuple([x[1], x[2]...]...))) |> table

common_feat_pearsons = [x for x in reduce((a,c) -> (push!(a[1], (i=a[2], N=sample_size, feature=c, cor=([gi, ob] .|> x -> select(x, c) |> x -> StatsBase.sample(x, sample_size, replace=false)) |> x -> round(OnlineStats.cor(x[1], x[2]), digits=2))); a[2] = a[2] + 1; a), intersect(colnames(gi), colnames(ob))[8:34], init=[[], 1])[1]] |> table

## Covarience
gi_cov = ((reduce((a,c) -> (push!(a[1], round.([v for v in map(x -> OnlineStats.cov(select(gi, c), select(gi, x)), a[2])], digits=2)); a[2] = a[2][2:end]; a), colnames(gi)[8:38], init=[[], colnames(gi)[8:38]])[1] .|> x -> vcat([Missing for z in 1:1:(31-length(x))], x)) |> m -> zip(colnames(gi)[8:38], m) .|> x -> NamedTuple{tuple(:features, colnames(gi)[8:38]...)}(tuple([x[1], x[2]...]...))) |> table

ob_cov = ((reduce((a,c) -> (push!(a[1], round.([v for v in map(x -> OnlineStats.cov(select(ob, c), select(ob, x)), a[2])], digits=2)); a[2] = a[2][2:end]; a), colnames(ob)[8:39], init=[[], colnames(ob)[8:39]])[1] .|> x -> vcat([Missing for z in 1:1:(32-length(x))], x)) |> m -> zip(colnames(ob)[8:39], m) .|> x -> NamedTuple{tuple(:features, colnames(ob)[8:39]...)}(tuple([x[1], x[2]...]...))) |> table

common_feat_cov = [x for x in reduce((a,c) -> (push!(a[1], (i=a[2], N=sample_size, feature=c, cov=([gi, ob] .|> x -> select(x, c) |> x -> StatsBase.sample(x, sample_size, replace=false)) |> x -> round(OnlineStats.cov(x[1], x[2]), digits=2))); a[2] = a[2] + 1; a), intersect(colnames(gi), colnames(ob))[8:34], init=[[], 1])[1]] |> table

## Unequal variance t-test
gi_uvt = ((reduce((a,c) -> (push!(a[1], round.([v for v in map(x -> HypothesisTests.UnequalVarianceTTest(select(gi, c), select(gi, x)) |> pvalue, a[2])], digits=2)); a[2] = a[2][2:end]; a), colnames(gi)[8:38], init=[[], colnames(gi)[8:38]])[1] .|> x -> vcat([Missing for z in 1:1:(31-length(x))], x)) |> m -> zip(colnames(gi)[8:38], m) .|> x -> NamedTuple{tuple(:features, colnames(gi)[8:38]...)}(tuple([x[1], x[2]...]...))) |> table

ob_uvt = ((reduce((a,c) -> (push!(a[1], round.([v for v in map(x -> HypothesisTests.UnequalVarianceTTest(select(ob, c), select(ob, x)) |> pvalue, a[2])], digits=2)); a[2] = a[2][2:end]; a), colnames(ob)[8:39], init=[[], colnames(ob)[8:39]])[1] .|> x -> vcat([Missing for z in 1:1:(32-length(x))], x)) |> m -> zip(colnames(ob)[8:39], m) .|> x -> NamedTuple{tuple(:features, colnames(ob)[8:39]...)}(tuple([x[1], x[2]...]...))) |> table

feat_uvt = [x for x in reduce((a,c) -> (push!(a[1], (i=a[2], feature=c, pvalue=(([gi, ob] .|> x -> select(x, c)) |> x -> round(HypothesisTests.UnequalVarianceTTest(x[1], x[2]) |> pvalue, digits=2)))); a[2] = a[2] + 1; a), intersect(colnames(gi), colnames(ob))[8:34], init=[[], 1])[1]] |> table

gi_uvt_per_feat_nonunique = (reduce((a,c) -> (map(x -> push!(a[1], [c, x, HypothesisTests.UnequalVarianceTTest(select(gi, c), select(gi, x)) |> pvalue |> p -> round(p, digits=2)]), a[2][2:end]); a), colnames(gi)[8:38], init=[[], colnames(gi)[8:38]])[1] .|> z -> NamedTuple{tuple(:x, :y, :pval)}(tuple(z...))) |> table |> t -> filter(x -> x.pval > 0.39 && x.x != x.y, sort(t, :pval, rev=true))

ob_uvt_per_feat_nonunique = (reduce((a,c) -> (map(x -> push!(a[1], [c, x, HypothesisTests.UnequalVarianceTTest(select(ob, c), select(ob, x)) |> pvalue |> p -> round(p, digits=2)]), a[2][2:end]); a), colnames(ob)[8:39], init=[[], colnames(ob)[8:39]])[1] .|> z -> NamedTuple{tuple(:x, :y, :pval)}(tuple(z...))) |> table |> t -> filter(x -> x.pval > 0.39 && x.x != x.y, sort(t, :pval, rev=true))

### Filter duplicates (too agressive, see and use CSVs)
# ((reduce((a,c) -> (a[2] = a[2][2:end]; foreach(v -> push!(a[1], (v.x == c.y || v.y == c.x) && v.pval == c.pval ? c : Missing), a[2]); a), gi_uvt_per_feat_nonunique |> rows, init=[[], gi_uvt_per_feat_nonunique |> rows])[1] |> unique |> x -> vcat(x[1], x[3:end])) .|> z -> NamedTuple{tuple(:x, :y, :pval)}(values(z))) |> table
# ((reduce((a,c) -> (a[2] = a[2][2:end]; foreach(v -> push!(a[1], (v.x == c.y || v.y == c.x) && v.pval == c.pval ? c : Missing), a[2]); a), ob_uvt_per_feat_nonunique |> rows, init=[[], ob_uvt_per_feat_nonunique |> rows])[1] |> unique)[2:end] .|> z -> NamedTuple{tuple(:x, :y, :pval)}(values(z))) |> table

gi_uvt_per_feat = loadtable("data/Milestones/2017-2018/NO_DELETE_UneqVarTTest_GIB-p_gt_0.4.csv");
ob_uvt_per_feat = loadtable("data/Milestones/2017-2018/NO_DELETE_UneqVarTTest_OBD-p_gt_0.4.csv");

## Theta
gi_bool_feats = map(x -> maximum(x[1]) < 3 ? x[2] : missing, columns(select(gi, Between(8,38))) |> x -> zip(values(x), keys(x))) |> skipmissing |> collect
ob_bool_feats = map(x -> maximum(x[1]) < 3 ? x[2] : missing, columns(select(ob, Between(8,39))) |> x -> zip(values(x), keys(x))) |> skipmissing |> collect

gi_th = map(x -> (l=length(x[1]); c=count(i -> i == 1, x[1]); NamedTuple{(:feature,:N,:len,:θ)}((x[2], c, l, round(c/l, digits=2)))), gi_bool_feats .|> x -> (select(gi, x), x)) |> table
ob_th = map(x -> (l=length(x[1]); c=count(i -> i == 1, x[1]); NamedTuple{(:feature,:N,:len,:θ)}((x[2], c, l, round(c/l, digits=2)))), ob_bool_feats .|> x -> (select(ob, x), x)) |> table

## Write CSV
[
    ("DescriptiveStats_GIB.csv", gi_summary),
    ("DescriptiveStats_OBD.csv", ob_summary),
    ("Pearsons-r_GIB.csv", gi_pearsons),
    ("Pearsons-r_OBD.csv", ob_pearsons),
    ("Pearsons-r_by_common_feature.csv", common_feat_pearsons),
    ("Covariance_GIB.csv", gi_cov),
    ("Covariance_OBD.csv", ob_cov),
    ("Covariance_by_common_feature.csv", common_feat_cov),
    ("UneqVarTTest_GIB.csv", gi_uvt),
    ("UneqVarTTest_OBD.csv", ob_uvt),
    ("UneqVarTTest_by_common_feature.csv", feat_uvt),
    ("Theta_GIB.csv", gi_th),
    ("Theta_OBD.csv", ob_th)
] .|> x -> CSV.write(x...)

# Plots
gi_feats_names = [String(x) for x in colnames(select(gi, Between(8,38)))];
ob_feats_names = [String(x) for x in colnames(select(ob, Between(8,39)))];

## Heatmaps
### Pearson's
Plots.savefig(Plots.heatmap((convert(Matrix, select(gi_pearsons, Between(2,32)) |> DataFrame) .|> x -> typeof(x) == DataType ? 0.0 : x)) |> yflip!, "Pearsons-r_GIB_heatmap");
Plots.savefig(Plots.heatmap((convert(Matrix, select(ob_pearsons, Between(2,33)) |> DataFrame) .|> x -> typeof(x) == DataType ? 0.0 : x)) |> yflip!, "Pearsons-r_OBD_heatmap");

### Covariance
Plots.savefig(Plots.heatmap((convert(Matrix, select(gi_cov, Between(2,32)) |> DataFrame) .|> x -> typeof(x) == DataType ? 0.0 : x)) |> yflip!, "Covariance_GIB_heatmap");
Plots.savefig(Plots.heatmap((convert(Matrix, select(ob_cov, Between(2,33)) |> DataFrame) .|> x -> typeof(x) == DataType ? 0.0 : x)) |> yflip!, "Covariance_OBD_heatmap");

### Unequal Variance t-test
Plots.savefig(Plots.heatmap((convert(Matrix, select(gi_uvt, Between(2,32)) |> DataFrame) .|> x -> typeof(x) == DataType ? 0.0 : x)) |> yflip!, "UneqVarTTest_GIB_heatmap");
Plots.savefig(Plots.heatmap((convert(Matrix, select(ob_uvt, Between(2,33)) |> DataFrame) .|> x -> typeof(x) == DataType ? 0.0 : x)) |> yflip!, "UneqVarTTest_OBD_heatmap");

## Histograms
### Durations
map(x -> filter(v -> v < x, select(gi, :minutes)), [8301, 1250, 201, 151, 101, 61, 46, 31]) .|> x -> Plots.savefig(Plots.histogram(x, legend=false, bins=:scott, title="GI Bleed, duration < $(maximum(x))min (N=$(length(x)))"), "GIB_lt$(maximum(x)).pdf");

map(x -> filter(v -> v < x, select(ob, :minutes)), [8301, 1250, 201, 151, 101, 61, 46, 31]) .|> x -> Plots.savefig(Plots.histogram(x, legend=false, bins=:scott, title="Obstructed Bile Duct, duration < $(maximum(x))min (N=$(length(x)))"), "OBD_lt$(maximum(x)).pdf");

### GI
Plots.savefig((@df gi StatsPlots.histogram(cols(8:16), legend=false, titlefont=font(8), xticks=[1,2,3], layout=9, label="", bins=:scott, title=reshape(gi_feats_names[1:9],1,9))), "GI_Bleed_1_hist.pdf");
Plots.savefig((@df gi StatsPlots.histogram(cols(17:25), legend=false, titlefont=font(8), xticks=[1,2,3], layout=9, label="", bins=:scott, title=reshape(gi_feats_names[10:18],1,9))), "GI_Bleed_2_hist.pdf");
Plots.savefig((@df gi StatsPlots.histogram(cols(26:34), legend=false, titlefont=font(8), xticks=[1,2,3], layout=9, label="", bins=:scott, title=reshape(gi_feats_names[19:27],1,9))), "GI_Bleed_3_hist.pdf");
Plots.savefig((@df gi StatsPlots.histogram(cols(35:38), legend=false, titlefont=font(8), xticks=[1,2,3], layout=4, label="", bins=:scott, title=reshape(gi_feats_names[28:31],1,4))), "GI_Bleed_4_hist.pdf");

### OBD
Plots.savefig((@df ob StatsPlots.histogram(cols(8:16), legend=false, titlefont=font(8), xticks=[1,2,3], layout=9, label="", bins=:scott, title=reshape(ob_feats_names[1:9],1,9))), "OBD_1_hist.pdf");
Plots.savefig((@df ob StatsPlots.histogram(cols(17:25), legend=false, titlefont=font(8), xticks=[1,2,3], layout=9, label="", bins=:scott, title=reshape(ob_feats_names[10:18],1,9))), "OBD_2_hist.pdf");
Plots.savefig((@df ob StatsPlots.histogram(cols(26:34), legend=false, titlefont=font(8), xticks=[1,2,3], layout=9, label="", bins=:scott, title=reshape(ob_feats_names[19:27],1,9))), "OBD_3_hist.pdf");
Plots.savefig((@df ob StatsPlots.histogram(cols(35:39), legend=false, titlefont=font(8), xticks=[1,2,3], layout=5, label="", bins=:scott, title=reshape(ob_feats_names[28:32],1,5))), "OBD_4_hist.pdf");

## Scatter Plots
### GI
Plots.savefig((@df gi StatsPlots.scatter(cols(8:16), legend=false, titlefont=font(8), markersize=2, markerstrokewidth=0, layout=9, label="", title=reshape(gi_feats_names[1:9],1,9))), "GI_Bleed_1_scatter.pdf");
Plots.savefig((@df gi StatsPlots.scatter(cols(17:25), legend=false, titlefont=font(8), markersize=2, markerstrokewidth=0, layout=9, label="", title=reshape(gi_feats_names[10:18],1,9))), "GI_Bleed_2_scatter.pdf");
Plots.savefig((@df gi StatsPlots.scatter(cols(26:34), legend=false, titlefont=font(8), markersize=2, markerstrokewidth=0, layout=9, label="", title=reshape(gi_feats_names[19:27],1,9))), "GI_Bleed_3_scatter.pdf");
Plots.savefig((@df gi StatsPlots.scatter(cols(35:38), legend=false, titlefont=font(8), markersize=2, markerstrokewidth=0, layout=4, label="", title=reshape(gi_feats_names[28:31],1,4))), "GI_Bleed_4_scatter.pdf");

### OBD
Plots.savefig((@df ob StatsPlots.scatter(cols(8:16), legend=false, titlefont=font(8), markersize=2, markerstrokewidth=0, layout=9, label="", bins=:scott, title=reshape(ob_feats_names[1:9],1,9))), "OBD_1_scatter.pdf");
Plots.savefig((@df ob StatsPlots.scatter(cols(17:25), legend=false, titlefont=font(8), markersize=2, markerstrokewidth=0, layout=9, label="", bins=:scott, title=reshape(ob_feats_names[10:18],1,9))), "OBD_2_scatter.pdf");
Plots.savefig((@df ob StatsPlots.scatter(cols(26:34), legend=false, titlefont=font(8), markersize=2, markerstrokewidth=0, layout=9, label="", bins=:scott, title=reshape(ob_feats_names[19:27],1,9))), "OBD_3_scatter.pdf");
Plots.savefig((@df ob StatsPlots.scatter(cols(35:39), legend=false, titlefont=font(8), markersize=2, markerstrokewidth=0, layout=5, label="", bins=:scott, title=reshape(ob_feats_names[28:32],1,5))), "OBD_4_scatter.pdf");

## Density Plots
### GI
# Plots.savefig((@df gi StatsPlots.density(cols(8:16), legend=false, titlefont=font(8), xticks=[1,2,3], layout=9, label="", title=reshape(gi_feats_names[1:9],1,9))), "GI_Bleed_1_den.pdf");
# Plots.savefig((@df gi StatsPlots.density(cols(17:25), legend=false, titlefont=font(8), xticks=[1,2,3], layout=9, label="", title=reshape(gi_feats_names[10:18],1,9))), "GI_Bleed_2_den.pdf");
# Plots.savefig((@df gi StatsPlots.density(cols(26:34), legend=false, titlefont=font(8), xticks=[1,2,3], layout=9, label="", title=reshape(gi_feats_names[19:27],1,9))), "GI_Bleed_3_den.pdf");
# Plots.savefig((@df gi StatsPlots.density(cols(35:38), legend=false, titlefont=font(8), xticks=[1,2,3], layout=4, label="", title=reshape(gi_feats_names[28:31],1,4))), "GI_Bleed_4_den.pdf");

### OBD
# Plots.savefig((@df ob StatsPlots.density(cols(8:16), legend=false, titlefont=font(8), xticks=[1,2,3], layout=9, label="", title=reshape(ob_feats_names[1:9],1,9))), "OBD_1_den.pdf");
# Plots.savefig((@df ob StatsPlots.density(cols(17:25), legend=false, titlefont=font(8), xticks=[1,2,3], layout=9, label="", title=reshape(ob_feats_names[10:18],1,9))), "OBD_2_den.pdf");
# Plots.savefig((@df ob StatsPlots.density(cols(26:34), legend=false, titlefont=font(8), xticks=[1,2,3], layout=9, label="", title=reshape(ob_feats_names[19:27],1,9))), "OBD_3_den.pdf");
# Plots.savefig((@df ob StatsPlots.density(cols(35:39), legend=false, titlefont=font(8), xticks=[1,2,3], layout=5, label="", title=reshape(ob_feats_names[28:32],1,5))), "OBD_4_den.pdf");