using Distributions
# Punch list
# - [ ] Integrate Rocuronium
# - [ ] Integrate Propofol

# patient is 80kg
# :mass_range (first array) is dose*80kg
drugs = [
    (label = :fentanyl, mass_range=160:1:1600, alt_mass_range=missing, concentration=50., unit="ug"),
    (label = :propofol, mass_range=1.5:0.1:2.5, alt_mass_range=missing, concentration=10., unit="mg"),
    (label = :rocuronium, mass_range=2.0:0.1:5.6, alt_mass_range=missing, concentration=10., unit="mg"),
    (label = :succinycholine, mass_range=80:0.1:120, alt_mass_range=[1.9,2.1], concentration=20., unit="mg")
]

durations = [ 
    (action = :preparation, d = Uniform(22, 63), lim=[22, 63]),
    (action = :fentanyl, d = Uniform(180, 300), lim=[180, 300]),
    (action = :time_to_apnea, d = Uniform(1, 2.5), lim=[1, 2.5]),
    (action = :succinycholine, d = Uniform(30, 45), lim=[30, 45]),
    (action = :laryngoscopy, d = Beta(2.5, 2), lim=[8, 32]),
    (action = :time_to_mech_vent, d = Uniform(4, 12), lim=[4, 12])
]

drugVolume(mass::Float64, concentration::Float64) = mass/concentration |> x -> round(x, digits=2)

function simulate(drugs, durations)
    [
        map(x -> rand(x.mass_range, 1) |> first |> v -> (label=x.label, dose=v, unit=x.unit), drugs),
        map(x -> (rand(x.d, 1) |> first |> v -> (action=x.action, duration=(Beta{Float64} == (x.d |> typeof) ? (v*x.lim[1]) + x.lim[1] : v))), durations) |> X -> push!(X, (action=:tail, duration=90.))
    ] |> X -> (drug_doses=X[1], sequence=X[2])
end


function test(sim)
    # println("## Drugs ##")
    # foreach(X -> println("$(X[1]) [$(X[2][1]), $(X[2][2])]"),
    #     [
    #         ["fentanyl []", filter(x -> x.label == :fentanyl, sim.drug_doses)[1].dose |> v -> [v, "CHECK"]],
    #         # ["rocuronium []", filter(x -> x.label == :rocuronium)[1].dose |> v -> [v, v >= 0.025]],
    #         ["succinycholine []", filter(x -> x.label == :succinycholine, sim.drug_doses)[1].dose |> v -> [v, "CHECK"]]
    #     ]
    # )

    # println("## Durations ##")
    map(X -> ("$(X[1])$(ismissing(X[2][2]) ? "" : " seconds")? => ($(round(X[2][1], digits=2)), $(X[2][2] == 1.0))"),
        [
            ["preoxygenation [180, ∞]", filter(x -> x.action in (:fentanyl, :time_to_apnea), sim.sequence) |> t -> select(t, :duration) |> sum |> v -> [v, v >= 180.]],
            ["fentanyl [180,300]", filter(x -> x.action == :fentanyl, sim.sequence)[1].duration |> v -> [v, v >= 180 && v <= 300]],
            ["succinycholine [30,45]", filter(x -> x.action == :succinycholine, sim.sequence)[1].duration |> v -> [v, v >= 30 && v <= 45]],
            ["tail [90]", [90, true]],
            ["duration of laryngoscopy", filter(x -> x.action == :laryngoscopy, sim.sequence)[1].duration |> v -> [v, missing]],
            ["time to mechanical ventilation", filter(x -> x.action == :mech_vent, sim.sequence)[1].duration |> v -> [v, missing]]
        ]
    ) |> X -> join(X, "\n")
end