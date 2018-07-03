# using Graft
# using Lazy, LightXML

mutable struct BGScenario
    document::LightXML.XMLDocument
    root::LightXML.XMLElement               # Scenario
    init::Array{LightXML.XMLElement, 1}   # InitialParameters || EngineStateFile
    name::LightXML.XMLElement
    description::LightXML.XMLElement
    dataRequests::Array{LightXML.XMLElement, 1}
    actions::Array{LightXML.XMLElement, 1}
    BGScenario(r) = new(XMLDocument(), r)
end

data_requests = [
        ["xsi:type" => "PhysiologyDataRequestData", "Name" => "HeartRate", "Unit" => "1/min"],
        ["xsi:type" => "PhysiologyDataRequestData", "Name" => "MeanArterialPressure", "Unit" => "mmHg"],
        ["xsi:type" => "PhysiologyDataRequestData", "Name" => "OxygenSaturation"]
    ]

function newbgs()
    scenario_attr = [
        "xmlns" => "uri:/mil/tatrc/physiology/datamodel",
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
        "xsdVersion" => "v16.12",
        "contentVersion" => "BioGears_6.0.1-beta",
        "xsi:schemaLocation" => ""
    ]

    sc = @> "Scenario" ne
    @> sc set_attributes(scenario_attr)
    BGScenario(sc)
end

ne(e::String) = @> e new_element
chldtxt(r::LightXML.XMLElement, c::String, t::String) = @> r new_child(c) add_text(t)

x = XMLDocument()

sc = @> "Scenario" ne
@> sc set_attributes(scenario_attr)
@> x set_root(sc)

@> sc chldtxt("Name", "John Stuart")
@> sc chldtxt("Description", "John Stuart RSI GraphBuilder.jl test file")

ip = @> "InitialParameters" ne
@> ip chldtxt("PatientFile", "JohnStuart.xml")
@> sc add_child(ip)

drqs = @> "DataRequests" ne
@> drqs set_attribute("Filename", "../JohnStuartRSI-072016/data/orig/001.csv")

drq = @>> data_requests map(x -> (x, ne("DataRequest")))
@>> drq foreach(x -> set_attributes(x[2], x[1]))
@>> drq foreach(x -> add_child(drqs, x[2]))

@> sc add_child(drqs)

act = @> "Action" ne @> set_attribute("xsi:type", "AdvanceTimeData")
@> act set_attribute("xsi:type", "AdvanceTimeData")

c = @> "Comment" ne
@> c add_text("w00t! w00t! w00t! w00t! w00t! w00t! w00t! w00t! w00t!")
add_child(act, c)

t = @> "Time" ne
@> t set_attributes(["value" => "99", "unit" => "s"])
add_child(act, t)
add_child(sc, act)

save_file(x, "BioGears_Scenario_GraphBuilder_$(Dates.now()).xml")