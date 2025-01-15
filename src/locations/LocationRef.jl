struct LocationRef
    id::Integer
    name::String 
    type::DataType
end 


location_id(x::LocationRef)=x.id
name(x::LocationRef)=x.name 

function Base.show(io::IO,x::LocationRef)
    print(io,"REF: $(name(x))")
end 

location_type(x::LocationRef)=x.type

occupancy_cost(parent::Location,child::LocationRef)= occupancy_cost(parent,location_type(child)(location_id(child),name(child)))