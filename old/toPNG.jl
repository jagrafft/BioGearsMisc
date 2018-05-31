searchdir(path,key) = filter(x->contains(x,key), readdir(path))

root = "data/JohnStuartRSI_BioGears"

for dir in readdir(root)
    if dir != ".DS_Store"
        println("$root/$dir")
        for csv in searchdir("$root/$dir", ".csv")
            println("\t$csv")
            df = @from i in CSV.read("$root/$dir/$csv") begin
                 @select {
                    s = get(i.s),
                    SpO2 = get(i.spO2) * 100,
                    MAP = get(i.map),
                    HR = get(i.hr)
                 }
                 @collect DataFrame
            end
            p = plot(df, x=:s, y=Col.value(:SpO2,:MAP,:HR),color=Col.index(:SpO2,:MAP,:HR),Geom.line)
            name = replace(csv, ".csv", "")
            draw(PNG("$root/$name-$dir.png",9inch,6inch),p)
        end
    end
end