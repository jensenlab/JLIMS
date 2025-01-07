
# internal constants and methods 
const roundtolerance=4
prefquantunits(::Solid)=u"g"
prefquantunits(::Liquid)=u"mL"

SolidDict=Dict{Solid,Unitful.Mass}
LiquidDict=Dict{Liquid,Unitful.Volume}


"""
    abstract type Stock end 

`Stock` objects represent combinations of organisms and chemicals quantities. 

"""
abstract type Stock end 

"""
    struct Empty <:Stock end 

Singleton type that represents an empty Stock object.
"""    
struct Empty <:Stock end 
  



"""
    struct Mixture <:Stock 

`Mixture` objects are stocks that only contain [`Solid`](@ref) components. Mixtures must contain at least one solid. (Otherwise, they would be [`Empty`](@ref) stocks.)

"""
struct Mixture <:Stock  
    solids::SolidDict
    function Mixture(solids)
        for solid in chemicals(solids)
            x=ustrip(solids[solid])
            x >= 0 || throw(DomainError(x,"$solid must have a non-negative mass")) 
        end 
        length(solids) >= 1 || throw(DomainError(length(solids),"mixtures must contain at least one solid"))
        new(solids)
    end 
end 


"""
    struct Solution <:Stock 

`Solution` objects are stocks that only contain at least one [`Liquid`](@ref) component but no organisms. Solutions may contain any number of [`Solid`](@ref) components

"""
struct Solution <: Stock 
    solids::SolidDict
    liquids::LiquidDict
    function Solution(solids,liquids)  
        # test for issues 
        for solid in chemicals(solids)
            x=ustrip(solids[solid])
            x >= 0 || throw(DomainError(x,"$solid must have a non-negative mass")) 
        end
        for liquid in chemicals(liquids)
            x=ustrip(liquids[liquid])
            x >= 0 || throw(DomainError(x,"$liquid must have a non-negative volume")) 
        end
        length(liquids) >= 1 || throw(DomainError(length(liquids),"solutions must contain at least one liquid"))
        return new(solids,liquids)
    end
end 

"""
    struct Culture <: Stock 

`Culture` objects are stocks that contain at least one [`Strain`](@ref). Cultures may contain any number of [`Solid`](@ref) or [`Liquid`](@ref) components.
"""
struct Culture <: Stock 
    organisms::Set{Strain}
    solids::SolidDict
    liquids::LiquidDict
    function Culture(organisms,solids,liquids)  
        # test for issues 
        for solid in chemicals(solids)
            x=ustrip(solids[solid])
            x >= 0 || throw(DomainError(x,"$solid must have a non-negative mass")) 
        end
        for liquid in chemicals(liquids)
            x=ustrip(liquids[liquid])
            x >= 0 || throw(DomainError(x,"$liquid must have a non-negative volume")) 
        end
        length(organisms) >= 1 || throw(DomainError(length(organisms),"solutions must contain at least one liquid"))
        return new(organisms, solids,liquids)
    end
end 

"""
    solids(::Stock)

access the solids Dict for a Stock. If no solids are present, return SolidDict()
"""
solids(c::Stock)=c.solids
solids(::Empty)=SolidDict() # Empty doesn't have a solids property


"""
    liquids(::Stock)

access the liquids Dict for a Stock. If no liquids are present, return LiquidDict()
"""
liquids(c::Stock)=c.liquids
liquids(::Empty)=LiquidDict() # Empty doesn't have a liquids property
liquids(c::Mixture)=LiquidDict() # Mixture doesn't have a liquids property


"""
    quantity(::Empty)

returns `missing` for the quantity of an Empty Stock
"""
quantity(c::Empty)=missing 

"""
    quantity(::Mixture)

returns the sum of each solid's mass in a Mixture
"""
function quantity(c::Mixture)
    s= values(solids(c))
    if length(s) == 0 
        return 0u"g"
    else
        return sum(s)
    end 
end 

"""
    quantity(::Stock)

returns the sum of each liquid's volume in a Stock
"""
function quantity(c::Stock)
    s=values(liquids(c))
    if length(s)==0
        return 0u"mL"
    else
        return sum(s)
    end 
end 


"""
    organisms(::Stock) 
return the `organisms` property of a Stock. If no organisms, are present, return Set{Strain}(). 
"""
organisms(c::Stock)=Set{Strain}()
organisms(c::Culture)=c.organisms



"""
    function Stock(organisms,solids,liquids)

a generic stock constructor that returns the appropriate stock subtype. 
"""
function Stock(organisms,solids,liquids) 
    o=length(organisms)
    s=length(solids)
    l=length(liquids)
    if o > 0 
        return Culture(organisms,solids,liquids)
    elseif o==0 && l > 0 
        return Solution(solids,liquids)
    elseif o==0 && l ==0 && s>0
        return Mixture(solids)
    else
        return Empty()
    end 
end 




"""
    chemicals(x::Union{SolidDict,LiquidDict})

a wrapper for `collect(keys(x))` that returns an array of the chemical keys.
"""
function chemicals(x::Union{SolidDict,LiquidDict})

    return collect(keys(x))
end 


# trivial constructors for mixtures and solutions 




"""
    *(quantity::Unitful.Amount,chemical::Solid)

Overload the `*` operator to construct a Mixture from a molar quantity of a solid. 
"""
function *(quantity::Unitful.Amount,chemical::Solid) 
    return Mixture(SolidDict(chemical => convert(prefquantunits(chemical),quantity,chemical)))
end 

"""
    *(quantity::Unitful.Mass,chemical::Solid)

Overload the `*` operator to construct a Mixture from a mass of a solid. 
"""
function *(quantity::Unitful.Mass,chemical::Solid) 
    return Mixture(SolidDict(chemical => uconvert(prefquantunits(chemical),quantity)))
end
"""
    *(quantity::Unitful.Mass,chemical::Solid)

Overload the `*` operator to construct a Solution from a volume of a liquid. 
"""
function *(quantity::Unitful.Volume,chemical::Liquid) 
    return Solution(SolidDict(),LiquidDict(chemical=>uconvert(prefquantunits(chemical),quantity)))
end 



"""
    *(num::Number,stock::Stock)

Overload the `*` operator to multiply the chemicals of a Stock by a scalar. Returns a new Stock with all chemical quantities scaled by a factor of `num`. 
"""
function *(num::Number,stock::Stock)
    new_solids=Dict{Solid,Unitful.Mass}()
    new_liquids=Dict{Liquid,Unitful.Volume}()
    for solid in chemicals(solids(stock))
        new_solids[solid]=solids(stock)[solid] * num 
    end 
    for liquid in chemicals(liquids(stock))
        new_liquids[liquid]=liquids(stock)[liquid]*num
    end 
    return Stock(organisms(stock),new_solids,new_liquids)
end 

*(stock::Stock,num::Number) = *(num,stock)

"""
    /(stock::Stock,num::Number)

Overload the `/` operator to divide a Stock by a scalar. Returns a new Stock with all chemical quantities scaled by a factor of `num` 
"""
/(stock::Stock,num::Number) = *(1/num,stock)



function Base.show(io::IO,::MIME"text/plain",s::Empty;digits::Integer=2)
    printstyled(io, "Empty Stock";bold=true)
end 
function Base.show(io::IO,s::Empty;digits::Integer=2)
    printstyled(io, "Empty Stock";bold=true)
end 
function Base.show(io::IO,::MIME"text/plain",s::Mixture;digits::Integer=2)
    typstr=string(typeof(s))
    q=quantity(s)
    printstyled(io,round(q;digits=digits)," ";bold=true)
    printstyled(io, "$typstr ($(length(solids(s))) chemical(s))\n";bold=true)
    arr_sol=sort(chemicals(solids(s)),by=name)
    vals =round.(map(x->uconvert(u"percent",solids(s)[x]/q),arr_sol);digits=digits)
    df_sol=DataFrame(Solids=arr_sol,Concentration=vals)
    show(io,df_sol;eltypes=false,show_row_number=false,summary=false)
    print(io,"\n\n")
end

function Base.show(io::IO,::MIME"text/plain",s::Solution;digits::Integer=2)
    typstr=string(typeof(s))
    q=quantity(s)
    printstyled(io,round(q;digits=digits)," ";bold=true)
    printstyled(io, "$typstr ($(length(solids(s))+length(liquids(s))) chemical(s))\n";bold=true)
    if length(solids(s)) > 0
        massunit=unit(sum(values(solids(s))))
        arr_sol=sort(chemicals(solids(s)),by=name)
        vals =round.(map(x->uconvert(massunit/unit(q),solids(s)[x]/q),arr_sol);digits=digits)
        df_sol=DataFrame(Solids=arr_sol,Concentration=vals)
        show(io,df_sol;eltypes=false,show_row_number=false,summary=false)
        print(io,"\n\n")
    end 
    arr_liq=sort(chemicals(liquids(s)),by=name)
    vals =round.(map(x->uconvert(u"percent",liquids(s)[x]/q),arr_liq);digits=digits)
    df_liq=DataFrame(Liquids=arr_liq,Concentration=vals)
    show(io,df_liq;eltypes=false,show_row_number=false,summary=false)
end 
function Base.show(io::IO,::MIME"text/plain",s::Culture;digits::Integer=2)
    typstr=string(typeof(s))
    q=quantity(s)
    printstyled(io,round(q;digits=digits)," ";bold=true)
    printstyled(io, "$typstr ($(length(solids(s))+length(liquids(s))) chemical(s))\n";bold=true)
    arr_org=sort(collect(organisms(s)),by=name)
    df_org=DataFrame(Organisms=arr_org)
    show(io,df_org;eltypes=false,show_row_number=false,summary=false)
    print(io,"\n\n")
    if length(solids(s)) > 0
        massunit=unit(sum(values(solids(s))))
        arr_sol=sort(chemicals(solids(s)),by=name)
        vals =round.(map(x->uconvert(massunit/unit(q),solids(s)[x]/q),arr_sol);digits=digits)
        df_sol=DataFrame(Solids=arr_sol,Concentration=vals)
        show(io,df_sol;eltypes=false,show_row_number=false,summary=false)
        print(io,"\n\n")
    end 
    if length(liquids(s)) > 0
        volunit=unit(sum(values(liquids(s))))
        arr_liq=sort(chemicals(liquids(s)),by=name)
        vals =round.(map(x->uconvert(u"percent",liquids(s)[x]/q),arr_liq);digits=digits)
        df_liq=DataFrame(Liquids=arr_liq,Concentration=vals)
        show(io,df_liq;eltypes=false,show_row_number=false,summary=false)
        print(io,"\n\n")
    end
end 
function Base.show(io::IO,s::Stock;digits::Integer=2)
    typstr=string(typeof(s))
    if !ismissing(quantity(s))
        printstyled(io,round(quantity(s);digits=digits)," ";bold=true)
    end 
    printstyled(io, "$typstr ($(length(solids(s))+length(liquids(s))) chemical(s))";bold=true)
end 


function quantity_split(x::Unitful.Quantity) 
    return (ustrip(x),string(Unitful.unit(x)))
end 

function component_display(s::Empty;concentration=true,digits=2)
    out_solids=Dict{String,Tuple{Number,String}}()
    out_liquids=Dict{String,Tuple{Number,String}}()
    out_organisms=Vector{String}[]
    return out_solids,out_liquids,out_organisms
end 

function component_display(s::Mixture;concentration=true,digits=2)
    out_solids=Dict{String,Tuple{Number,String}}()
    out_liquids=Dict{String,Tuple{Number,String}}()
    out_organisms=Vector{String}[]
    q=quantity(s)
    arr_sol=sort(chemicals(solids(s)),by=name)
    vals=round.(map( x-> solids(s)[x],arr_sol);digits=digits)
    if concentration
        vals =round.(map(x->uconvert(u"percent",solids(s)[x]/q),arr_sol);digits=digits)
    end 
    out_solids=Dict{String,Tuple{Number,String}}(map(x->name(x),arr_sol) .=> quantity_split.(vals))
    return out_solids,out_liquids,out_organisms
end 

function component_display(s::Solution;concentration=true,digits=2)
    out_solids=Dict{String,Tuple{Number,String}}()
    out_liquids=Dict{String,Tuple{Number,String}}()
    out_organisms=Vector{String}[]
    q=quantity(s)
    if length(solids(s))>0 
        arr_sol=sort(chemicals(solids(s)),by=name)
        vals=round.(map( x-> solids(s)[x],arr_sol);digits=digits)
        if concentration
            massunit=unit(sum(values(solids(s))))
            vals =round.(map(x->uconvert(massunit/unit(q),solids(s)[x]/q),arr_sol);digits=digits)
        end 
        out_solids=Dict{String,Tuple{Number,String}}(map(x->name(x),arr_sol) .=> quantity_split.(vals))
    end 
    arr_liq=sort(chemicals(liquids(s)),by=name)
    vals=round.(map( x-> liquids(s)[x],arr_liq);digits=digits)
    if concentration 
        vals =round.(map(x->uconvert(u"percent",liquids(s)[x]/q),arr_liq);digits=digits)
    end 
    out_liquids=Dict{String,Tuple{Number,String}}(map(x->name(x),arr_liq) .=> quantity_split.(vals))
    return out_solids,out_liquids,out_organisms
end 

function component_display(s::Culture;concentration=true,digits=2)
    out_solids=Dict{String,Tuple{Number,String}}()
    out_liquids=Dict{String,Tuple{Number,String}}()
    out_organisms=Vector{String}[]
    q=quantity(s)
    if length(solids(s))>0 
        arr_sol=sort(chemicals(solids(s)),by=name)
        vals=round.(map( x-> solids(s)[x],arr_sol);digits=digits)
        if concentration
            massunit=unit(sum(values(solids(s))))
            vals =round.(map(x->uconvert(massunit/unit(q),solids(s)[x]/q),arr_sol);digits=digits)
        end 
        out_solids=Dict{String,Tuple{Number,String}}(map(x->name(x),arr_sol) .=> quantity_split.(vals))
    end 
    arr_liq=sort(chemicals(liquids(s)),by=name)
    vals=round.(map( x-> liquids(s)[x],arr_liq);digits=digits)
    if concentration 
        vals =round.(map(x->uconvert(u"percent",liquids(s)[x]/q),arr_liq);digits=digits)
    end 
    out_liquids=Dict{String,Tuple{Number,String}}(map(x->name(x),arr_liq) .=> quantity_split.(vals))
    out_organisms=sort(collect(organisms(s)),by=name)
    return out_solids,out_liquids,out_organisms
end







"""
    volume_estimate(s::Stock) 

Return the estimated volume of a Stock `s` 

- *Empty* returns a value of `missing`
- *Mixture* approximates the volume based on the density of each chemical. If one or more chemicals has a missing density, `volume_estimate` returns a value of 0u"mL"
- *Solution* returns `quantity(s)`
"""
volume_estimate(s::Stock) = quantity(s)
volume_estimate(s::Empty)=0u"mL"

function volume_estimate(m::Mixture)
    vol=0u"mL"
    sols=solids(m)
    for sol in chemicals(sols)
        q=sols[sol]
        vol+= q/density(sol)
    end
    if ismissing(vol)
        return 0u"mL"
    else
        return vol
    end
end 


function ==(a::Stock,b::Stock) 
    all([organisms(a)==organisms(b),solids(a)==solids(b),liquids(a)==liquids(b)])
end 


function Base.in(str::Strain,stock::Stock)
    return str in organisms(stock)
end 

function Base.in(sol::Solid,stock::Stock)
    return sol in chemicals(solids(stock))
end 

function Base.in(liq::Liquid,stock::Stock)
    return liq in chemicals(liquids(stock))
end 