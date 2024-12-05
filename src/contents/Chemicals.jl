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



struct Solid <: Chemical 
    name::String
    molecular_weight::Union{Unitful.MolarMass,Missing}
    density::Union{Unitful.Density,Missing}
    pubchemid::Union{Integer,Missing}
end 

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

A macro to define a new chemical and import it into the workspace under `labname`. The `name` argument is the display name for the chemical, which can include a larger set of characters and formatting than the `labname`
    
There are three valid type parameters for chemicals: 
1) Solid
2) Liquid
3) Gas

For a given chemical, its type parameter should be the phase in which it exists at STP. 

We provide the optional argument for `pubchemid` to access the Pub Chem database for chemicals. Attaching a pubchemid to a chemical triggers a call to the PUG REST API to query the molecular weight and density of the chemical. 

Chemicals can also be defined manually with type constructors.

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

Unitful uconvert wrapper a chemical quantity from a molar quantity to a mass quantity and vice-versa.

`convert` accesses the chemical's stored properties to make the conversion using the Unitful.uconvert function.

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




