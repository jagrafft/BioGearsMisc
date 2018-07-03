# using Graft
using Lazy, LightXML

mutable struct BGScenario
    document::LightXML.XMLDocument
    root::LightXML.XMLElement               # Scenario
    name::LightXML.XMLElement
    description::LightXML.XMLElement
    init::LightXML.XMLElement               # InitialParameters || EngineStateFile
    dataRequests::LightXML.XMLElement
    actions::Array{LightXML.XMLElement, 1}
    BGScenario(r) = new(XMLDocument(), r)
end

data_requests = [
        ["xsi:type" => "PhysiologyDataRequestData", "Name" => "HeartRate", "Unit" => "1/min"],
        ["xsi:type" => "PhysiologyDataRequestData", "Name" => "MeanArterialPressure", "Unit" => "mmHg"],
        ["xsi:type" => "PhysiologyDataRequestData", "Name" => "OxygenSaturation"]
    ]

function NewBGS()
    attr = [
        "xmlns" => "uri:/mil/tatrc/physiology/datamodel",
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
        # "xsdVersion" => "v16.12",
        "contentVersion" => "BioGears_6.0.1-beta",
        "xsi:schemaLocation" => ""
    ]

    s = @> "Scenario" new_element
    @> s set_attributes(attr)
    @> s BGScenario
end

function ExportBGS(s::BGScenario)
    x = s.document
    @> x set_root(s.root)
    @> s.root add_child(s.name)
    @> s.root add_child(s.description)
    @> s.root add_child(s.init)
    @> s.root add_child(s.dataRequests)
    @>> s.actions foreach(a -> @> s.root add_child(a))
    save_file(x, "BG_Scenario_Builder_$(Dates.now()).xml")
end

function action(t::String)
    a = new_element("Action")
    @> a set_attribute("xsi:type", t)
    a
end

chldattr(r::LightXML.XMLElement, c::String, a) = @> r new_child(c) set_attributes(a)

chldtxt(r::LightXML.XMLElement, c::String, t::String) = @> r new_child(c) add_text(t)

bgs = NewBGS()

name = @> "Name" new_element
@> name add_text("John Stuart")
bgs.name = name

desc = @> "Description" new_element
@> desc add_text("John Stuart RSI GraphBuilder.jl test file")
bgs.description = desc

ip = @> "InitialParameters" new_element
@> ip chldtxt("PatientFile", "JohnStuart.xml")
bgs.init = ip

drqs = @> "DataRequests" new_element
@> drqs set_attribute("Filename", "w00t.csv")
drq = @>> data_requests map(x -> (x, new_element("DataRequest")))
@>> drq foreach(x -> set_attributes(x[2], x[1]))
@>> drq foreach(x -> add_child(drqs, x[2]))
bgs.dataRequests = drqs

a1 = action("AdvanceTimeData")
@> a1 chldtxt("Comment", "w00t! w00t! w00t! w00t! w00t! w00t! w00t! w00t! w00t!")
@> a1 chldattr("Time", ["value" => "99", "unit" => "s"])

a2 = action("SubstanceBolusData")
@> a2 set_attribute("AdminRoute", "Intravenous")
@> a2 chldtxt("Substance", "Rocuronium")
@> a2 chldattr("Concentration", ["value" => "0.1", "unit" => "mg/mL"])
@> a2 chldattr("Dose", ["value" => "70.0", "unit" => "mL"])

a3 = action("AdvanceTimeData")
@> a3 chldattr("Time", ["value" => "69", "unit" => "s"])

bgs.actions = [a1, a2, a3]