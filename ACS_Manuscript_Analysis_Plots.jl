# ETI Attempts
rng_eti  = [-1:0.001:5...];
png((Plots.plot(rng_eti, StatsFuns.normpdf.(1.61, 0.91, rng_eti), label="John Stuart (Study)"); Plots.plot!(rng_eti, StatsFuns.normpdf.(1.06, 0.24, rng_eti), label="Clinically Proficient", title="Priors: ETI Attempts"); Plots.plot!(rng_eti, StatsFuns.normpdf.(1.21, 0.66, rng_eti), label="Clinical Novice")), "ETIAttempts_Priors-All.png")

png((Plots.plot(rng_eti, StatsFuns.normpdf.(1.61, 0.91, rng_eti), label="John Stuart (Study)"); Plots.plot!(rng_eti, StatsFuns.normpdf.(1.32, 0.98, rng_eti), label="Clinically Proficient", title="Posteriors: ETI Attempts"); Plots.plot!(rng_eti, StatsFuns.normpdf.(1.55, 0.96, rng_eti), label="Clinical Novice")), "ETIAttempts_Posteriors-All.png")

## !CN
png((Plots.plot(rng_eti, StatsFuns.normpdf.(1.61, 0.91, rng_eti), label="John Stuart (Study)"); Plots.plot!(rng_eti, StatsFuns.normpdf.(1.06, 0.24, rng_eti), label="Clinically Proficient", title="Priors: ETI Attempts")), "ETIAttempts_Priors.png")

png((Plots.plot(rng_eti, StatsFuns.normpdf.(1.61, 0.91, rng_eti), label="John Stuart (Study)"); Plots.plot!(rng_eti, StatsFuns.normpdf.(1.32, 0.98, rng_eti), label="Clinically Proficient", title="Posteriors: ETI Attempts")), "ETIAttempts_Posteriors.png")

# Preoxygenation
rng_preox = [0:0.001:1...];
png((Plots.plot(rng_preox, StatsFuns.betapdf.(15,6,rng_preox), label="John Stuart (Beta(15,6))"); Plots.plot!(rng_preox, StatsFuns.betapdf.(45,29,rng_preox), legend=:topleft, label="Clinically Proficient (Beta(45,29))"); Plots.plot!(rng_preox, StatsFuns.betapdf.(24, 19,rng_preox), label="Clinical Novice (Beta(24, 19))", title="Priors: Preoxygenation >= 3min")), "PreoxygenationGTE3min_Priors-All.png")

## !CN
png((Plots.plot(rng_preox, StatsFuns.betapdf.(15,6,rng_preox), label="John Stuart (Beta(15,6))"); Plots.plot!(rng_preox, StatsFuns.betapdf.(45,29,rng_preox), legend=:topleft, label="Clinically Proficient (Beta(45,29))", title="Priors: Preoxygenation >= 3min")), "PreoxygenationGTE3min_Priors.png")