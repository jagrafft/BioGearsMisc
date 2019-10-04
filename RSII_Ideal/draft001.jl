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
    (label = :succinylcholine, mass_range=120:1:160, concentration=20., unit="mg")
]

durations = [ 
    (action = :preparation, d = Uniform(22, 63), lim=[22, 63]),
    (action = :drug_offset, d = Uniform(18, 45), lim=[18, 45]),
    (action = :fentanyl, d = Uniform(180, 300), lim=[180, 300]),
    (action = :to_rr0, d = Uniform(1, 2.5), lim=[1, 2.5]),
    (action = :succinylcholine, d = Uniform(30, 45), lim=[30, 45]),
    (action = :laryngoscopy, d = Beta(2.5, 2), lim=[8, 32]),
    (action = :to_mech_vent, d = Uniform(4, 12), lim=[4, 12])
]

# drugVolume(mass::Float64, concentration::Float64) = mass/concentration |> x -> round(x, digits=2)

# total_time = preparation + preoxygenation + apnea_duration + laryngoscopy + time_to_mech_vent + tail
# preoxygenation = drug_offset + fentanyl - succinylcholine + to_rr0 # >180sec

function action_sequence(durations, drugs)
    drg = map(x -> rand(x.mass_range, 1) |> first |> v -> x.label => (dose=v, unit=x.unit), drugs) |> Dict
    dur = map(x -> rand(x.d, 1) |> first |>  v -> x.action => (dur = (Beta{Float64} == (x.d |> typeof) ? (v*x.lim[1]) + x.lim[1] : v)), durations) |> X -> push!(X, :tail => 90) |> Dict
    
    preox = dur[:drug_offset] + dur[:fentanyl] - dur[:succinylcholine] + dur[:to_rr0]

    [
        (event=:simulation, action=:start, t=0),
        (event=:preparation, action=:start, t=0),
        (event=:preoxygenation, action=:start, t=dur[:preparation]),
        (event=:preparation, action=:end, t=dur[:preparation]),
        (event=:fentanyl, action=:bolus, dose=(drg[:fentanyl] |> values |> X -> join(X, "")), t=(dur[:preparation] + dur[:drug_offset])),
        (event=:succinylcholine, action=:bolus, dose=(drg[:succinylcholine] |> values |> X -> join(X, "")), t=(dur[:preparation] + preox - dur[:to_rr0])),
        (event=:apnea, action=:start, t=(dur[:preparation] + preox)),
        (event=:preoxygenation, action=:end, t=(dur[:preparation] + preox)),
        (event=:laryngoscopy, action=:start, t=(dur[:preparation] + preox + dur[:succinylcholine] - dur[:to_rr0])),
        (event=:laryngoscopy, action=:end, t=(dur[:preparation] + preox + dur[:succinylcholine] - dur[:to_rr0] + dur[:laryngoscopy])),
        (event=:mechanical_ventilations, action=:start, t=(dur[:preparation] + preox + dur[:succinylcholine] - dur[:to_rr0] + dur[:laryngoscopy] + dur[:to_mech_vent])),
        (event=:simulation, action=:end, t=(dur[:preparation] + preox + dur[:succinylcholine] - dur[:to_rr0] + dur[:laryngoscopy] + dur[:to_mech_vent] + 90.0))
    ] .|> t -> (t_ = (t=round(t.t, digits=2), event=t.event, action=t.action); haskey(t, :dose) ? merge(t_, (dose=t.dose,)) : t_)
end

_dur(X) = X[2].t - X[1].t |> x -> round(x, digits=2)

function evaluate_sequence(seq)
    lar_start = filter(x -> x.event == :laryngoscopy && x.action == :start, seq) |> first
    [
        # preox >= 180sec
        filter(x -> x.event == :preoxygenation, seq) |> X -> (dur=_dur(X); (criterion=:preoxygenation, dur=dur, range=180, inRange=dur >= 180)),
        # fentanyl administration [180,300]sec prior to laryngoscopy
        filter(x -> x.event == :fentanyl, seq) |> X -> push!(X, lar_start) |> X -> (dur=_dur(X); (criterion=:fentanyl_admin, dur=dur, range=180:300, inRange=dur >= 180 && dur <= 300)),
        # succinylcholine administration [30,45]sec prior to laryngoscopy
        filter(x -> x.event == :succinylcholine, seq)|> X -> push!(X, lar_start) |> X -> (dur=_dur(X); (criterion=:succinylcholine_admin, dur=dur, range=30:45, inRange=dur >= 30 && dur <= 45))
    ]
end