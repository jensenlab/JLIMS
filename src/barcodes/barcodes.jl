mutable struct Barcode 
   const id::UUID
    const name::Union{String,Missing}
    location_id::Union{Integer,Missing}
    Barcode(id::UUID,name::String=missing,location_id::Union{Integer,Missing}=missing)=new(id,name,location_id)
end 


barcode(x::Barcode)=x.id 
location_id(x::Barcode)=x.location_id
name(x::Barcode)=x.name



function assign_barcode!(barcode::Barcode,location::Location)
        loc_id=location_id(barcode)
        if !ismissing(loc_id) && loc_id !== location_id(location) 
            error("barcode already assigned to another location")
        else
            barcode.location_id=location_id(location)
            return nothing 
        end 
end 


function assign_barcode(barcode::Barcode,location::Location)
    bc=deepcopy(barcode)
    assign_barcode!(bc,location)
    return bc
end 
