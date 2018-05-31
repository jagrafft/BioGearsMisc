df = @from i in CSV.read("data/JohnStuartRSI_BioGears/orig/004.csv") begin
        @select {
            s = get(i.s),
            SpO2 = get(i.spO2) * 100,
            MAP = get(i.map),
            HR = get(i.hr)
        }
        @collect DataFrame
    end

lt = @from i in df begin
        @where i.SpO2 < 90.
        @select i
        @collect DataFrame
     end

p = plot(
        layer(df, x=:s, y=:MAP, Geom.line, Theme(default_color=color("orange"))),
        layer(df, x=:s, y=:HR, Geom.line, Theme(default_color=color("green"))),
        layer(lt, x=:s, y=:SpO2, Geom.line, Theme(default_color=color("red"))),
        layer(df, x=:s, y=:SpO2, Geom.line, Theme(default_color=color("deepskyblue"))),
        Guide.manual_color_key("Legend", ["MAP", "HR", "SpO2 ≥ 90%"], ["orange", "green", "deepskyblue"])
);