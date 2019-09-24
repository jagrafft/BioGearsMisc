using Distributions

# Punch list
# - [ ] Integrate Rocuronium
# - [ ] Integrate Propofol

# patient is 80kg
# :mass_range (first array) is dose*80kg
drugs = Dict{Symbol,NamedTuple{(:mass_range, :alt_mass_range, :concentration, :con_units),T} where T<:Tuple}(
    :fentanyl => (mass_range=160:1:1600, alt_mass_range=missing, concentration=50., con_units="ug/mL"),
    # rocuronium => (mass_range=[2.,5.6], alt_mass_range=missing, concentration=10., con_units="mg/mL"),
    :succs => (mass_range=80:0.1:120, alt_mass_range=[1.9,2.1], concentration=20., con_units="mg/mL"),
    # propofol => (mass_range=[1.5,2.5], alt_mass_range=missing, concentration=10., con_units="mg/mL")
)

drugVolume(mass::Float64, concentration::Float64) = mass/concentration |> x -> round(x, digits=2)

function simulate()
    durations = Dict{Symbol,NamedTuple{(:d, :lim),T} where T<:Tuple}(
        :preox => (d = Truncated(Normal(180, 100), 180, 180+100*4), lim=[180, missing]),
        :laryngoscopy => (d = Beta(2.5, 2), lim=[8,32]),
        :fentanyl => (d = Uniform(180, 300), lim=[180, 300]),
        :succs => (d = Uniform(30, 45), lim=[30, 45]),
        :mech_vent => (d = Beta(2.5, 2), lim=[4, 12]),
        :apnea_offset => (d = Truncated(Normal(3, 0.2), 2.4, 3.8), lim=[2.4, 3.8])
    )

    # fentanyl dose
    df = rand(drugs[:fentanyl].mass_range, 1) |> first

    # succs dose
    ds = rand(drugs[:succs].mass_range, 1) |> first

    # preox duration
    pd = rand(durations[:preox].d, 1) |> first

    # laryngoscopy duration
    ld = rand(durations[:laryngoscopy].d, 1) |> first |> x -> x * (durations[:laryngoscopy].lim[2] - durations[:laryngoscopy].lim[1])+ durations[:laryngoscopy].lim[1]

    # fentanyl duration
    fd = rand(durations[:fentanyl].d, 1) |> first

    # succs duration
    sd = rand(durations[:succs].d, 1) |> first

    # attach mech_vent duration
    mvd = rand(durations[:mech_vent].d, 1) |> first |> x -> x * (durations[:mech_vent].lim[2] - durations[:mech_vent].lim[1])+ durations[:mech_vent].lim[1]

    # apnea offset 
    oa = rand(durations[:apnea_offset].d, 1) |> first    

    # time to laryngoscopy =  preoxygenation dur + (succs dur - apnea offset) |> x -> x > fentanyl dur ? x : (fentanyl dur - x)*2 + x
    ttl = pd + (sd - oa) |> x -> x > fd ? x : x + (fd - x)*2 

    # time of preoxygenation start = time to laryngoscopy - preoxygenation dur
    ap = ttl - pd

    # time of fentanyl admin = time to laryngoscopy - fentanyl dur
    af = ttl - fd
    
    # time of succs admin = time to laryngoscopy - succs dur
    as = ttl - sd    

    # time to mechanical vent = time to laryngoscopy + laryngoscopy duration + attach mech_vent duration
    ttmv = ttl + ld + mvd

    # return sorted (implicitly) by length? I believe they should...
    (total=ttmv, time_to_lar=ttl, time_fent_admin=af, dose_fent="$(df)ug", dur_fent=fd, time_succs_admin=as, dose_succs="$(ds)mg", dur_succs=sd, dur_apnea_offset=-oa, dur_lar=ld, dur_mv_wait=mvd, time_tail=90.0)
end