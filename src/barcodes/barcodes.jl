mutable struct Barcode 
   const id::UUID
    const name::String
    location_id::Union{Integer,Missing}
    Barcode(id::UUID,name::String,location_id::Union{Integer,Missing}=missing)=new(id,name,location_id)
end 


barcode(x::Barcode)=x.id 
location_id(x::Barcode)=x.location_id
name(x::Barcode)=x.name



function assign_barcode!(barcode::Barcode,location::Location)
        barcode.location_id=location_id(location)
    return nothing 
end 


function assign_barcode(barcode::Barcode,location::Location)
    bc=deepcopy(barcode)
    assign_barcode!(bc,location)
    return bc
end 

