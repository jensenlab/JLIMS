struct LocationRef
    id::Integer
    name::String 
    type::DataType
end 


location_id(x::LocationRef)=x.id
name(x::LocationRef)=x.name 

AbstractTrees.nodevalue(x::Location)=location_id(x)
AbstractTrees.ParentLinks(::Type{<:Location})=StoredParent()

function Base.show(io::IO,x::LocationRef)
    print(io,name(x))
end 

