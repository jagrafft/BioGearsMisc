searchdir(path,key) = filter(x->contains(x,key), readdir(path))
root = "data/JohnStuartRSI_BioGears"

for csv in searchdir("$root/orig", ".csv")
    println(csv)
    a = @from i in CSV.read("$root/orig/$csv") begin @select {s = get(i.s), SpO2 = get(i.spO2)*100, MAP = get(i.map), HR = get(i.hr)} @collect DataFrame end
    b = @from i in CSV.read("$root/10cmH2O/$csv") begin @select {s = get(i.s), SpO2 = get(i.spO2)*100, MAP = get(i.map), HR = get(i.hr)} @collect DataFrame end
    c = @from i in CSV.read("$root/0cmH2O/$csv") begin @select {s = get(i.s), SpO2 = get(i.spO2)*100, MAP = get(i.map), HR = get(i.hr)} @collect DataFrame end

    pa = plot(a, x=:s, y=Col.value(:SpO2, :MAP, :HR), color=Col.index(:SpO2, :MAP, :HR), Geom.line, Guide.title("Ventilator Pressure = 20cmH2O"))
    pb = plot(b, x=:s, y=Col.value(:SpO2, :MAP, :HR), color=Col.index(:SpO2, :MAP, :HR), Geom.line, Guide.title("Ventilator Pressure = 10cmH2O"))
    pc = plot(c, x=:s, y=Col.value(:SpO2, :MAP, :HR), color=Col.index(:SpO2, :MAP, :HR), Geom.line, Guide.title("Ventilator Pressure = 0cmH2O"))

    name = replace(csv, ".csv", "")
    draw(PNG("$root/$name.png",12inch,16inch),vstack(pa,pb,pc))
end