function get_attribute(attr::String)
    return eval(Symbol(attr))
end

function get_component(id::Integer)
    comp_type=query_db("SELECT Type FROM Components WHERE ID=$id")
    if nrow(comp_type)==0
        error("component $id does not exist in the database")
    else 
        comp_type=comp_type[1,1]
    end 

    if comp_type == "Chemical" 
        c = query_db("SELECT Name, Type,MolecularWeight,Density,CID FROM Chemicals WHERE ComponentID = $id")[1,:]
        typ=eval(Symbol(c["Type"]))
        return typ(c["Name"],c["MolecularWeight"]*u"g/mol",c["Density"]*u"g/mL",c["CID"])

    elseif comp_type =="Strain"
        c= query_db("SELECT Genus, Species, Strain FROM Strains WHERE ComponentID = $id")[1,:]
        return Strain(c["Genus"],c["Species"],c["Strain"])
    else
        error("component $id not found in the database")
        return nothing
    end 
end


function get_location_info(id::Integer)
    loc_info=query_db("SELECT * FROM Locations WHERE ID =$id")
    if nrow(loc_info) == 0 
        error("location id not found")
    end 
    out=loc_info[1,:]
    return string(out["Name"]), eval(Symbol(out["Type"]))
end 