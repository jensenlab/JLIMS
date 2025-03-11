

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
    unit(x::Attribute)

Access the `unit` property of an [`Attribute`](@ref)
"""
attribute_unit(x::Attribute)=x.unit
"""
    quantity(x::Attribute)

Return the quantity of an [`Attribute`](@ref)
"""
quantity(x::Attribute) = value(x) *attribute_unit(x)

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
macro attribute(name, unit)
    n=Symbol(name)

    if isdefined(__module__,n) || isdefined(JLIMS,n)
        throw(ArgumentError("Attribute type $n already exists"))
    end 

    return esc(quote
    export $n
    un_type=typeof($unit)
    mutable struct $n <: (JLIMS.Attribute)
        value::Union{Real,Missing}  
        const unit::un_type
        function ($n)(value::Union{Unitful.Quantity,Missing})
            val=Unitful.ustrip(Unitful.uconvert($unit,value))
            new(val,$unit)
        end 
    end
    end
    )
end



Base.show(io::IO,x::Attribute;digits=2) = print(io,round(quantity(x),digits=digits))

function ==(x::Attribute,y::Attribute)
    return typeof(x)==typeof(y) && quantity(x)==quantity(y)
end 

function Base.hash(a::Attribute,h::UInt)
    hash(typeof(a),hash(quantity(a),h))
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


