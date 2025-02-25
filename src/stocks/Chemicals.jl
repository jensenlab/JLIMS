

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
    @chemical labname name type molecular_weight density pubchemid


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

julia> @chemical water "water" Liquid 18.015u"g/mol" 1.00u"g/mL" 962
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
macro chemical(labsymb,name,type,molecular_weight,density,pubchemid)

    expr =Expr(:block)
    push!(expr.args,quote 
        Base.@__doc__ $JLIMS.@chemical_symbols $labsymb $name $type $molecular_weight $density $pubchemid 
        end 
    )

    push!(expr.args,quote
        $labsymb
    end )

    esc(expr)
end 



macro chemical_symbols(labsymb,name,type,molecular_weight,density,pubchemid)
    ls= Symbol(labsymb)
    ln = Meta.quot(ls)
    docstr= """
            $labsymb

        The $type chemical $name with [`PubChem ID`](https://pubchem.ncbi.nlm.nih.gov) $pubchemid  

        Molecular Weight: $molecular_weight
        Density: $density

        See also: [`$type`](@ref)
        """
    cprops = :($molecular_weight,$density,$pubchemid)  
    esc(quote

        $(chemprops_expr(__module__,ln,cprops))
        const global $ls = $type($name,$molecular_weight,$density,$pubchemid)
        @doc $docstr $ls 
    end)
end 





function chemprops_expr(m::Module,n,chemprops)
    if m === JLIMS
        :($(_chemprops(JLIMS))[$n]= $chemprops)
    else
        # We add the chemical properties to dictionaries in both JLIMS and the module `m` so that the factor is available in both
        quote 
            $(_chemprops(m))[$n]=$chemprops
            $(_chemprops(JLIMS))[$n]=$chemprops
        end 
    end 
end 




macro chem_str(chemical)
    ex = Meta.parse(chemical)
    labmods = [JLIMS]
    for m in JLIMS.labmodules
        # Find registered lab extension modules which are also loaded by
        # __module__ (required so that precompilation will work).
        if isdefined(__module__, nameof(m)) && getfield(__module__, nameof(m)) === m
            push!(labmods, m)
        end
    end
    esc(lookup_chemicals(labmods, ex))
end


function chemparse(str; chem_context=JLIMS)
    ex = Meta.parse(str)
    eval(lookup_chemicals(chem_context, ex))
end
function lookup_chemicals(labmods, sym::Symbol)
    has_chemical = m->(isdefined(m,sym) && chemstr_check_bool(getfield(m, sym)))
    inds = findall(has_chemical, labmods)
    if isempty(inds)
        # Check whether chemical exists in the global list to give an improved
        # error message.
        hintidx = findfirst(has_chemical, labmodules)
        if hintidx !== nothing
            hintmod = labmodules[hintidx]
            throw(ArgumentError(
                """Symbol `$sym` was found in the globally registered lab module $hintmod
                   but was not in the provided list of lab modules $(join(labmods, ", ")).

                   (Consider `using $hintmod` in your module if you are using `@chem_str`?)"""))
        else
            throw(ArgumentError("Symbol $sym could not be found in lab modules $labmods"))
        end
    end

    m = labmods[inds[end]]
    u = getfield(m, sym)

    any(u != u1 for u1 in getfield.(labmods[inds[1:(end-1)]], sym)) &&
        @warn """Symbol $sym was found in multiple registered lab modules.
                 We will use the one from $m."""
    return u
end

chemstr_check_bool(::Chemical) =true 
chemstr_check_bool(::Any) =false




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




