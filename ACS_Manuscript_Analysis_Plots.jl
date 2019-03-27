# ETI Attempts - Manuscript
rng_eti  = [-1:0.001:5...];

Plots.savefig((Plots.plot(rng_eti, StatsFuns.normpdf.(1.04, 0.20, rng_eti), label="Clinically Proficient (prior)", title="ETI Attempts for Noivce and Proficient (prior) Groups", color=:skyblue, titlefontsize=11, tickfontsize=5); Plots.plot!(rng_eti, StatsFuns.normpdf.(1.61, 0.91, rng_eti), label="Clinical Noivce", color=RGB([193,94,165] ./ 255...))), "figure-002-ETI_CP-prior.png");

Plots.savefig((Plots.plot(rng_eti, StatsFuns.normpdf.(1.04, 0.20, rng_eti), label="Clinically Proficient (prior)", title="ETI Attempts for Clinically Proficient Before and After Fitting", color=:skyblue, titlefontsize=11, tickfontsize=5); Plots.plot!(rng_eti, StatsFuns.normpdf.(1.00, 0.48, rng_eti), label="Clinically Proficient (posterior)", color=:orange)), "figure-003-ETI_CP-post.png");

# Duration of Apnea - Manuscript
rng_apnea = [-200:0.001:500...];

Plots.savefig((Plots.plot(rng_apnea, StatsFuns.normpdf.(167.56, 99.71, rng_apnea), label="Clinically Proficient (prior)", title="Duration of Apnea for Noivce and Proficient (prior) Groups", color=:skyblue, titlefontsize=11, tickfontsize=5); Plots.plot!(rng_apnea, StatsFuns.normpdf.(151.60, 81.66, rng_apnea), label="Clinical Noivce", color=RGB([193,94,165] ./ 255...))), "figure-004-DurationApnea_CP-prior.png");

Plots.savefig((Plots.plot(rng_apnea, StatsFuns.normpdf.(167.56, 99.71, rng_apnea), label="Clinically Proficient (prior)", title="Duration of Apnea for Clinically Proficient Before and After Fitting", color=:skyblue, titlefontsize=11, tickfontsize=4); Plots.plot!(rng_apnea, StatsFuns.normpdf.(110.00, 110.00, rng_apnea), label="Clinically Proficient (posterior)", color=:orange)), "figure-005-DurationApnea_CP-post.png");

cp_ap_dur = load("data/RSII/Iryna/subpopulations/jdb/apnea_duration-CP.jdb")
Plots.savefig(Plots.histogram(select(cp_ap_dur, 17), legend=false, xlabel="Minutes", title="Duration of Apnea for Patients of Clinically Proficient Providers", titlefontsize=11, tickfontsize=5), "figure-006-DurationApnea_Hist.png");

# Preoxygenation - Manuscript
red_green = [203,89,88], [96,168,97]] ./ 255 .|> x -> RGB(x...);

Plots.savefig(Plots.bar([0,1], [16,29], color=red_green, group=["< 3min", "=> 3min"], legend=:topleft, linewidth=0, title="Preoxygenation => 3min for Clinically Proficient (prior)", titlefontsize=11, tickfontsize=5, xticks=[]), "figure-007-CP_preox.png");

Plots.savefig(Plots.bar([0,1], [9,6], color=red_green, group=["< 3min", "=> 3min"], legend=:topright, linewidth=0, title="Preoxygenation => 3min for Clinical Novice", titlefontsize=11, tickfontsize=5, xticks=[]), "figure-008-CN_proex.png");

# Preoxygenation
rng_preox = [0:0.001:1...];
Plots.savefig((Plots.plot(rng_preox, StatsFuns.betapdf.(15,6,rng_preox), label="John Stuart (Beta(15,6))"); Plots.plot!(rng_preox, StatsFuns.betapdf.(45,29,rng_preox), legend=:topleft, label="Clinically Proficient (Beta(45,29))"); Plots.plot!(rng_preox, StatsFuns.betapdf.(24, 19,rng_preox), label="Clinical Novice (Beta(24, 19))", title="Priors: Preoxygenation >= 3min")), "PreoxygenationGTE3min_Priors-All.png")

## !CN
Plots.savefig((Plots.plot(rng_preox, StatsFuns.betapdf.(15,6,rng_preox), label="John Stuart (Beta(15,6))"); Plots.plot!(rng_preox, StatsFuns.betapdf.(45,29,rng_preox), legend=:topleft, label="Clinically Proficient (Beta(45,29))", title="Priors: Preoxygenation >= 3min")), "PreoxygenationGTE3min_Priors.png")