using Distributions, GR, LaTeXStrings, StatsPlots; gr(dpi=300, fmt=:png)

outd = "img/BioGears/RSII_Profiling/2019-09-17";
samples = (line = 1:1:1000, scat=10000);

# Functions
## Line Plots
p_(X, title, xlab) = StatsPlots.plot(X, xlabel=xlab, formatter=:auto, guidefontsize=6, legend=false, tickfontsize=4, title=title, titlefontsize=8);
p(d, r; title="", xlab="") = map(i -> d, r) |> X -> p_(X, title, xlab);
p(d, r, max; title="", xlab="") = map(i -> d, r) |> X -> (p_(X, title, xlab); StatsPlots.vline!([max], color=:red)) |> StatsPlots.plot;

## Scatter Plots
s(d, n, rng; title="", xlab="", ylab="", scale=false) = (
    arr = rand(d, n) |> x -> scale ? ((x .* (rng[2]-rng[1])) .+ rng[1]) : x;
    StatsPlots.scatter(arr, color=:black, formatter=:auto, guidefontsize=6, framestyle=:grid, legend=false, markersize=0.25, title=title, titlefontsize=8, tickfontsize=4, xlabel=xlab, ylabel=ylab); StatsPlots.hline!(rng, color=:red);
);

# Data
dists = [(2.5,2), (180,100), (180,300), (30,45), (2.5,2)] |> tup -> [
    (d = Beta(tup[1]...), l = "Duration of Laryngoscopy", t = latexstring("\\textnormal{Beta}$(tup[1])"), xlab="seconds", ylab="n", rng=[8,32], scale = true),
    (d = Truncated(Normal(tup[2]...), tup[2][1], tup[2][1] + tup[2][1]*5), l = "Duration of Preoxygenation", t = latexstring("\\textnormal{Truncated }\\mathcal{N}$(tup[2])"), xlab="seconds", ylab="n", rng=[0,180]),
    (d = Uniform(tup[3]...), l = "Fentanyl Administration to Laryngoscopy", t = latexstring("\\textnormal{Uniform}$(tup[3])"), xlab="seconds", ylab="n", rng=[tup[3]...]),
    (d = Uniform(tup[4]...), l = "Succinylcholine Administration to Laryngsocopy", t = latexstring("\\textnormal{Uniform}$(tup[4])"), xlab="seconds", ylab="n", rng=[tup[4]...]),
    (d = Beta(tup[5]...), l = "Time to Mechanical Ventilations", t = latexstring("\\textnormal{Beta}$(tup[5])"), xlab="seconds", ylab="n", rng=[4,12], scale = true)
];

# Draw Functions
## Line Plots (pdf curve)
# dists .|> t -> png((t.rng[1] == 0 ? p(t.d, samples.line; title=t.l, xlab=t.xlab) : p(t.d, samples.line, t.rng[2]; title=t.t, xlab=t.xlab)), "$(t.l)-pdf");

## Scatter Plots
# dists .|> t -> png((t.rng[1] == 0 ? s(t.d, samples.scat, [t.rng[2]]; title=t.t, xlab=t.ylab, ylab=t.xlab) : s(t.d, samples.scat, t.rng; title=t.l, xlab=t.ylab, ylab=t.xlab)), "$(t.l)-scatter");

### 2x1 {Line, Scatter}
zip(
    dists .|> t -> p(t.d, samples.line; xlab=t.xlab),
    dists .|> t -> (t.rng[1] == 0 ? s(t.d, samples.scat, [t.rng[2]]; xlab=t.ylab, ylab=t.xlab, scale=(:scale in keys(t))) : s(t.d, samples.scat, t.rng; xlab=t.ylab, ylab=t.xlab, scale=(:scale in keys(t))))
) |> collect |> z -> zip(z, dists .|> t -> (l=t.l, t=t.t)) |> collect .|> t -> png(Plots.plot(t[1]..., title=t[2].t), "$outd/$(t[2].l)");

### 10 2x1 {Line Scatter}
1:1:10 .|> it -> zip(
    dists .|> t -> p(t.d, samples.line; xlab=t.xlab),
    dists .|> t -> (t.rng[1] == 0 ? s(t.d, samples.scat, [t.rng[2]]; xlab=t.ylab, ylab=t.xlab) : s(t.d, samples.scat, t.rng; xlab=t.ylab, ylab=t.xlab))
) |> collect |> z -> zip(z, dists .|> t -> (l=t.l, t=t.t)) |> collect .|> t -> png(Plots.plot(t[1]..., title=t[2].t), "$outd/it/$(t[2].l)");
