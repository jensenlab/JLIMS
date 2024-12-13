struct Barcode 
    id::UUID
    location_id::Union{Integer,Missing}
    name::String
end 


barcode(x::Barcode)=barcode.id 
location_id(x::Barcode)=barcode.location_id
name(x::Barcode)=barcode.name



