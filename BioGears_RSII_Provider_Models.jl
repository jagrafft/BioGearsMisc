using Distributions, GR, LaTeXStrings, StatsPlots; gr(dpi=300, fmt=:png)

samples = (line = 1:1:1000, scat=10000);

# Functions
## Line Plots
p_(X, title, xlab) = StatsPlots.plot(X, xlabel=xlab, formatter=:auto, guidefontsize=6, legend=false, tickfontsize=4, title=title, titlefontsize=8);
p(d, r; title="", xlab="") = map(i -> d, r) |> X -> p_(X, title, xlab);
p(d, r, max; title="", xlab="") = map(i -> d, r) |> X -> (p_(X, title, xlab); StatsPlots.vline!([max], color=:red)) |> StatsPlots.plot;

## Scatter Plots
s(d, n, rng; title="", xlab="", ylab="") = (StatsPlots.scatter(rand(d, n), color=:black, formatter=:auto, guidefontsize=6, framestyle=:grid, legend=false, markersize=0.25, title=title, titlefontsize=8, tickfontsize=4, xlabel=xlab, ylabel=ylab); StatsPlots.hline!(rng, color=:red));

# Data
dists = [
    (d = [180,80], l = "Duration of Preoxygenation", xlab="seconds", ylab="n", rng=[0,180]),
    (d = [180,28], l = "Fentanyl Administration to Laryngoscopy", xlab="seconds", ylab="n", rng=[180,300]),
    (d = [30,3.6], l = "Succinylcholine Administration to Laryngsocopy", xlab="seconds", ylab="n", rng=[30,45])
] .|> t -> (d = Truncated(Normal(t.d[1], t.d[2]), t.d[1], t.d[1]+t.d[2]*5), l = t.l, rng = t.rng, xlab = t.xlab, ylab = t.ylab);

# Draw Functions
## Line Plots (pdf curve)
# dists .|> t -> png((t.rng[1] == 0 ? p(t.d, samples.line; title=t.l, xlab=t.xlab) : p(t.d, samples.line, t.rng[2]; title=t.l, xlab=t.xlab)), "$(t.l)-pdf");

## Scatter Plots
# dists .|> t -> png((t.rng[1] == 0 ? s(t.d, samples.scat, [t.rng[2]]; title=t.l, xlab=t.ylab, ylab=t.xlab) : s(t.d, samples.scat, t.rng; title=t.l, xlab=t.ylab, ylab=t.xlab)), "$(t.l)-scatter");

### 2x1 {Line, Scatter}
zip(
    dists .|> t -> (t.rng[1] == 0 ? p(t.d, samples.line; xlab=t.xlab) : p(t.d, samples.line, t.rng[2]; xlab=t.xlab)),
    dists .|> t -> (t.rng[1] == 0 ? s(t.d, samples.scat, [t.rng[2]]; xlab=t.ylab, ylab=t.xlab) : s(t.d, samples.scat, t.rng; xlab=t.ylab, ylab=t.xlab))
) |> collect |> z -> zip(z, dists .|> t -> (l=t.l, d=latexstring("\\mathcal{N}(", "$(t.d.untruncated.μ),$(t.d.untruncated.σ))"))) |> collect .|> t -> png(Plots.plot(t[1]..., title=t[2].d), t[2].l);

### 10 2x1 {Line Scatter}
1:1:10 .|> it -> zip(
    dists .|> t -> (t.rng[1] == 0 ? p(t.d, samples.line; xlab=t.xlab) : p(t.d, samples.line, t.rng[2]; xlab=t.xlab)),
    dists .|> t -> (t.rng[1] == 0 ? s(t.d, samples.scat, [t.rng[2]]; xlab=t.ylab, ylab=t.xlab) : s(t.d, samples.scat, t.rng; xlab=t.ylab, ylab=t.xlab))
) |> collect |> z -> zip(z, dists .|> t -> (l=t.l, d=latexstring("\\mathcal{N}(", "$(t.d.untruncated.μ),$(t.d.untruncated.σ))"))) |> collect .|> t -> png(Plots.plot(t[1]..., title=t[2].d), "$(t[2].l)-$(it)");