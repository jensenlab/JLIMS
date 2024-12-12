

"""
    abstract type Chemical end 

Represents a substance with a defined set of physical properties. Chemicals are used to identify the composition of various mixtures and substances in the lab.

All `Chemical` subtypes have four fields utilized by JLIMS: 
1) `name`: the name by which the chemical will be referred to 
2) `molecular_weight`: the chemical's molecualr weight, if known, is used by JLIMS to facilitate conversions between molar and mass quantities of the chemical. If `molecular_weight` is unknown or undefined, it is assigned a value of `missing`
3) `density`: the chemical's density at STP, if known, is used by JLIMS to facilitate conversions between mass and volume quantities of the chemical. If `density` is unknown or undefined, it is assigned a value of `missing`
4) `pubchemid`: the chemical's integer [PubChem ID](https://pubchem.ncbi.nlm.nih.gov) connects the chemical to registered substances in the pubchem database. the [`@chemical`](@ref) macro uses `pubchemid` to query the PubChem database for the chemical's properties automatically. 

"""
abstract type Chemical end 





Base.show(io::IO,chemical::Chemical)=print(io,name(chemical))

""" 
    name(x::Chemical) 

access the name property of a chemical
"""
name(x::Chemical)=x.name
"""
    molecular_weight(x::Chemical)

access the molecular_weight property of a chemical
"""
molecular_weight(x::Chemical)=x.molecular_weight
"""
    density(x::Chemical) 

access the density property of a chemical
"""
density(x::Chemical)=x.density

"""
    pubchemid(x::Chemical)

access the pubchemid property of a chemical
"""
pubchemid(x::Chemical)=x.pubchemid




"""
    struct Solid <: Chemical

Solids are [`Chemical`](@ref) subtypes that exist in solid phase at STP. We typically express solid quantities in terms of a mass or moles. 
"""
struct Solid <: Chemical 
    name::String
    molecular_weight::Union{Unitful.MolarMass,Missing}
    density::Union{Unitful.Density,Missing}
    pubchemid::Union{Integer,Missing}
end 
"""
    struct Liquid <: Chemical

Liquids are [`Chemical`](@ref) subtypes that exist in liquid phase at STP. We typically express liquid quantities in terms of a volume. 
"""
struct Liquid <: Chemical 
    name::String
    molecular_weight::Union{Unitful.MolarMass,Missing}
    density::Union{Unitful.Density,Missing}
    pubchemid::Union{Integer,Missing}
end

struct Gas <: Chemical 
    name::String
    molecular_weight::Union{Unitful.MolarMass,Missing}
    density::Union{Unitful.Density,Missing}
    pubchemid::Union{Integer,Missing}
end






"""
    @chemical labname name type pubchemid
    @chemical labname name type

Define a new chemical and import it into the workspace under `labname`. The `name` argument is the display name for the chemical, which can include a larger set of characters and formatting than the `labname`
    
There are three valid type parameters for chemicals: 
1) [`Solid`](@ref)
2) [`Liquid`](@ref)
3) [`Gas`](@ref)

For a given chemical, its `type` parameter should be the phase in which it exists at STP. 



We provide the optional argument for `pubchemid` to access the [PubChem](https://pubchem.ncbi.nlm.nih.gov) database. Attaching a pubchemid to a chemical triggers a call to the PUG REST API to query the molecular weight and density of the chemical. 
If no `pubchemid` is provided, the chemical is defined with `missing` for the `molecular_weight` and `density` properties.

Examples: 
```jldoctest
julia> using Unitful
julia> @chemical iron_nitrate "Iron (II) Nitrate" Solid

julia> iron_nitrate isa Chemical && iron_nitrate isa Solid
true

julia> @chemical water "water" Liquid 962
water

julia> molecular_weight(water)
18.015 g mol⁻¹
```

Chemicals can also be defined manually with type constructors.

Example:
```jldoctest
julia> water=Liquid("water",18.015u"g/mol",1.00u"g/mL",962)
water
```

See also: [`Solid`](@ref), [`Liquid`](@ref), [`Gas`](@ref)
"""
macro chemical(labname, name, type, pubchemid)
    ln=Symbol(labname)
    n=Base.string(name)
    t=Symbol(type)

    cid::Integer=eval(pubchemid)
    if isdefined(__module__,ln) || isdefined(JLIMS,ln)
        throw(ArgumentError("Chemical  $n already exists"))
    end 
    if !isdefined(__module__,t) && !isdefined(JLIMS,t)
        throw(ArgumentError("abstract Chemical type $t does not exist."))
    end
    mw,d=JLIMS.get_mw_density(cid)

    return esc(quote
        const $ln = $t($n,$mw * u"g/mol",$d * u"g/mL",$cid)  
    end)
end 

macro chemical(labname,name, type)
    ln=Symbol(labname)
    n=Base.string(name)
    t=Symbol(type)
    if isdefined(__module__,ln) || isdefined(JLIMS,ln)
        throw(ArgumentError("Chemical  $n already exists"))
    end 
    if !isdefined(__module__,t) && !isdefined(JLIMS,t)
        throw(ArgumentError("abstract Chemical type $t does not exist."))
    end

    return esc(quote
        const $ln = $t($n,missing,missing,missing)  
    end)
end






"""
    convert(desired_unit, current_unit, chemical::Chemical)

[Unitful.uconvert](https://painterqubits.github.io/Unitful.jl/stable/conversion/#Unitful.uconvert) wrapper to convert a chemical quantity from a molar quantity to a mass quantity and vice-versa.

`convert` accesses the chemical's stored properties to make the conversion using the [Unitful.uconvert](https://painterqubits.github.io/Unitful.jl/stable/conversion/#Unitful.uconvert) function.
"""
function convert(y::Unitful.MassUnits,x::Unitful.Amount,ingredient::Chemical)
    ismissing(molecular_weight(ingredient)) ? error("$(ingredient)'s molecular weight is unknown") : return uconvert(y,x *molecular_weight(ingredient))
end 

function convert(y::Unitful.AmountUnits,x::Unitful.Mass,ingredient::Chemical)
    ismissing(molecular_weight(ingredient)) ? error("$(ingredient)'s molecular weight is unknown") : return uconvert(y,x / molecular_weight(ingredient))
end 

function convert(y::Unitful.Density,x::Unitful.Molarity,ingredient::Chemical)
    ismissing(molecular_weight(ingredient)) ? error("$(ingredient)'s molecular weight is unknown") : return uconvert(y,x *molecular_weight(ingredient))
end 

function convert(y::Unitful.Molarity,x::Unitful.Density,ingredient::Chemical)
    ismissing(molecular_weight(ingredient)) ? error("$(ingredient)'s molecular weight is unknown") : return uconvert(y,x /molecular_weight(ingredient))
end




