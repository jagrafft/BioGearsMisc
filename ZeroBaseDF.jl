using DataFrames, Query

ctr = 0
# inc :: Int -> Int
function inc(n)
    global ctr
    ctr += n
end

# zerobase :: DataFrame -> DataFrame
function zerobase(df)
    start = first(df[:t])
    zerobaseT = vcat([0], map(x -> x - start, df[:t][2:end]))
    insert!(df[2:end], 1, zerobaseT, :Ts)
end

# zerobaseColon :: DataFrame -> DataFrame
function zerobaseColon(df)
    @from i in df begin
        # Multiple let statements currently error (29.05.2018)
        @let ts = (parse(Int64, convert(String, split(get(i.t), ":")[1]))*60) + parse(Int64, convert(String, split(get(i.t), ":")[2]))
        @select {Ts=ts, Event=i.event, Type=i.type, Notes=i.notes, Mg_kg=i.mg_kg, Mg=i.mg}
        @collect DataFrame
    end
end