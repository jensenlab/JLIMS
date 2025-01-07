struct LocationRef
    id::Integer
    name::String 
    type::DataType
end 


location_id(x::LocationRef)=x.id
name(x::LocationRef)=x.name 


function Base.show(io::IO,x::LocationRef)
    print(io,name(x))
end 

