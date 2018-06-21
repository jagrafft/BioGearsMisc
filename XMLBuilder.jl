# using Graft
using Lazy, LightXML

struct BGScenario
    document::LightXML.XMLDocument
    root::LightXML.XMLElement               # Scenario
    init::Array{LightXML.XMLElement, 1}   # InitialParameters || EngineStateFile
    name::LightXML.XMLElement
    description::LightXML.XMLElement
    dataRequests::Array{LightXML.XMLElement, 1}
    actions::Array{LightXML.XMLElement, 1}
end

scenario_attr = ["xmlns" => "uri:/mil/tatrc/physiology/datamodel", "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", "xsdVersion" => "v16.12", "contentVersion" => "BioGears_6.0.1-beta", "xsi:schemaLocation" => ""]

drq_attr_hr = ["xsi:type" => "PhysiologyDataRequestData", "Name" => "HeartRate", "Unit" => "1/min"]
drq_attr_map = ["xsi:type" => "PhysiologyDataRequestData", "Name" => "MeanArterialPressure", "Unit" => "mmHg"]
drq_attr_spo2 = ["xsi:type" => "PhysiologyDataRequestData", "Name" => "OxygenSaturation"]

ne(e::String) = @> e new_element

x = XMLDocument()
sc = @> "Scenario" new_element
set_attributes(sc, scenario_attr)
set_root(x, sc)
@> sc new_child("Name") add_text("John Stuart")
@> sc new_child("Description") add_text("John Stuart RSI GraphBuilder.jl test file")
ip = @> "InitialParameters" new_element
@> ip new_child("PatientFile") add_text("JohnStuart.xml")
add_child(sc, ip)
drqs = @> "DataRequests" new_element
set_attribute(drqs, "Filename", "../JohnStuartRSI-072016/data/orig/001.csv")
drq = @> "DataRequest" new_element
set_attributes(drq, drq_attr_hr)
add_child(drqs, drq)
drq = @> "DataRequest" new_element
set_attributes(drq, drq_attr_map)
add_child(drqs, drq)
drq = @> "DataRequest" new_element
set_attributes(drq, drq_attr_spo2)
add_child(drqs, drq)
add_child(sc, drqs)
act = @> "Action" ne
@> act set_attribute("xsi:type", "AdvanceTimeData")
c = @> "Comment" ne
@> c add_text("w00t! w00t! w00t! w00t! w00t! w00t! w00t! w00t! w00t!")
add_child(act, c)
t = @> "Time" ne
@> t set_attributes(["value" => "99", "unit" => "s"])
add_child(act, t)
add_child(sc, act)

save_file(x, "BioGears_Scenario_GraphBuilder_$(Dates.now()).xml")