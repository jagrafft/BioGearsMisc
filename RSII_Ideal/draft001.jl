using Distributions
# Punch list
# - [ ] Tests
# - [ ] Integrate Rocuronium
# - [ ] Integrate Propofol

# patient is 80kg
# :mass_range (first array) is dose*80kg
drugs = [
    (label = :fentanyl, mass_range=80:1:160, concentration=50., unit="ug"),
    (label = :propofol, mass_range=120:1:200, concentration=10., unit="mg"),
    (label = :rocuronium, mass_range=48:1:96, concentration=10., unit="mg"),
    (label = :succinycholine, mass_range=120:1:160, concentration=20., unit="mg")
]

durations = [ 
    (action = :preparation, d = Uniform(22, 63), lim=[22, 63]),
    (action = :drug_offset, d = Uniform(18, 45), lim=[18, 45]),
    (action = :fentanyl, d = Uniform(180, 300), lim=[180, 300]),
    (action = :to_rr0, d = Uniform(1, 2.5), lim=[1, 2.5]),
    (action = :succinycholine, d = Uniform(30, 45), lim=[30, 45]),
    (action = :laryngoscopy, d = Beta(2.5, 2), lim=[8, 32]),
    (action = :to_mech_vent, d = Uniform(4, 12), lim=[4, 12])
]

# drugVolume(mass::Float64, concentration::Float64) = mass/concentration |> x -> round(x, digits=2)

# total_time = preparation + preoxygenation + apnea_duration + laryngoscopy + time_to_mech_vent + tail
# preoxygenation = drug_offset + fentanyl - succinycholine + to_rr0 # >180sec

function action_sequence(durations, drugs)
    drg = map(x -> rand(x.mass_range, 1) |> first |> v -> x.label => (dose=v, unit=x.unit), drugs) |> Dict
    dur = map(x -> rand(x.d, 1) |> first |>  v -> x.action => (dur = (Beta{Float64} == (x.d |> typeof) ? (v*x.lim[1]) + x.lim[1] : v)), durations) |> X -> push!(X, :tail => 90) |> Dict
    
    preox = dur[:drug_offset] + dur[:fentanyl] - dur[:succinycholine] + dur[:to_rr0]

    [
        (event=:simulation, action=:start, t=0),
        (event=:preparation, action=:start, t=0),
        (event=:preoxygenation, action=:start, t=dur[:preparation]),
        (event=:preparation, action=:end, t=dur[:preparation]),
        (event=:fentanyl, action=:bolus, dose=(drg[:fentanyl] |> values |> X -> join(X, "")), t=(dur[:preparation] + dur[:drug_offset])),
        (event=:succinycholine, action=:bolus, dose=(drg[:succinycholine] |> values |> X -> join(X, "")), t=(dur[:preparation] + preox - dur[:to_rr0])),
        (event=:apnea, action=:start, t=(dur[:preparation] + preox)),
        (event=:preoxygenation, action=:end, t=(dur[:preparation] + preox)),
        (event=:laryngoscopy, action=:start, t=(dur[:preparation] + preox + dur[:succinycholine] - dur[:to_rr0])),
        (event=:laryngoscopy, action=:end, t=(dur[:preparation] + preox + dur[:succinycholine] - dur[:to_rr0] + dur[:laryngoscopy])),
        (event=:mechanical_ventilations, action=:start, t=(dur[:preparation] + preox + dur[:succinycholine] - dur[:to_rr0] + dur[:laryngoscopy] + dur[:to_mech_vent])),
        (event=:simulation, action=:end, t=(dur[:preparation] + preox + dur[:succinycholine] - dur[:to_rr0] + dur[:laryngoscopy] + dur[:to_mech_vent] + 90.0))
    ] .|> t -> (event=t.event, action=t.action, t=round(t.t, digits=2))
end

# function test(sim)
#     # println("## Drugs ##")
#     # foreach(X -> println("$(X[1]) [$(X[2][1]), $(X[2][2])]"),
#     #     [
#     #         ["fentanyl []", filter(x -> x.label == :fentanyl, sim.drug_doses)[1].dose |> v -> [v, "CHECK"]],
#     #         # ["rocuronium []", filter(x -> x.label == :rocuronium)[1].dose |> v -> [v, v >= 0.025]],
#     #         ["succinycholine []", filter(x -> x.label == :succinycholine, sim.drug_doses)[1].dose |> v -> [v, "CHECK"]]
#     #     ]
#     # )

#     # println("## Durations ##")
#     map(X -> ("$(X[1])$(ismissing(X[2][2]) ? "" : " seconds")? => ($(round(X[2][1], digits=2)), $(X[2][2] == 1.0))"),
#         [
#             ["preoxygenation [180, ∞]", filter(x -> x.action in (:fentanyl, :to_rr0), sim.sequence) |> t -> select(t, :duration) |> sum |> v -> [v, v >= 180.]],
#             ["fentanyl [180,300]", filter(x -> x.action == :fentanyl, sim.sequence)[1].duration |> v -> [v, v >= 180 && v <= 300]],
#             ["succinycholine [30,45]", filter(x -> x.action == :succinycholine, sim.sequence)[1].duration |> v -> [v, v >= 30 && v <= 45]],
#             ["tail [90]", [90, true]],
#             ["duration of laryngoscopy", filter(x -> x.action == :laryngoscopy, sim.sequence)[1].duration |> v -> [v, missing]],
#             ["time to mechanical ventilation", filter(x -> x.action == :mech_vent, sim.sequence)[1].duration |> v -> [v, missing]]
#         ]
#     ) |> X -> join(X, "\n")
# end