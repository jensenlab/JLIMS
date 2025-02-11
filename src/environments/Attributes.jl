

"""
    abstract type Attribute end

Attributes define the environmental properties of [`Location`](@ref) objects. 
"""
abstract type Attribute end


"""
    value(x::Attribute)

Access the `value` property of an [`Attribute`](@ref)
"""
value(x::Attribute)=x.value



"""
    @attribute name valuetype 

Define a new [`Attribute`](@ref) subtype `name`. Name stores a value of type `valuetype`

Example:
```julia-repl
julia> using Unitful
julia> @attribute Temperature Unitful.Temperature

julia> Temperature(10u"°C")
10 °C
```
See also: [`Attribute`](@ref)
"""
macro attribute(name, valuetype)
    n=Symbol(name)

    if isdefined(__module__,n) || isdefined(JLIMS,n)
        throw(ArgumentError("Attribute type $n already exists"))
    end 

    return esc(quote
    export $n
    mutable struct $n <: (JLIMS.Attribute)
        value::($valuetype) 
    end 
    end 
    )
end



Base.show(io::IO,x::Attribute) = print(io,value(x))

function ==(x::Attribute,y::Attribute)
    return typeof(x)==typeof(y) && value(x)==value(y)
end 

function Base.hash(a::Attribute,h::UInt)
    hash(typeof(a),hash(value(a),h))
end 

const AttributeDict=Dict{Type{<:Attribute},Attribute}





""" 
    set_attribute!(x::AttributeDict,attribute::Attribute)

Set the value for key `type(a)` of  `dict` to `attribute`. 

We use this method to ensure a proper pairing between the attribute type and the attribute in the dict.
"""
function set_attribute!(dict::AttributeDict,attribute::Attribute)
    dict[typeof(attribute)]=attribute ; 
    nothing 
end 

""" 
    set_attribute(dict::AttributeDict,attribute::Attribute)

Create a copy of `dict` Set the value for key `type(a)` of the copy to `attribute`. return the copy.
"""
function set_attribute(dict::AttributeDict,attribute::Attribute)
    y=deepcopy(dict)
    set_attribute!(y,attribute) 
    return y 
end 


