import Base.==

# internal constants and methods 
const roundtolerance=4
prefquantunits(::Solid)=u"g"
prefquantunits(::Liquid)=u"mL"




abstract type Composition end 


struct Empty <:Composition end 
  




struct Mixture <:Composition  
    solids::Dict{Solid,Unitful.Mass} 
    function Mixture(solids)
        for solid in chemicals(solids)
            x=ustrip(solids[solid])
            x >= 0 || throw(DomainError(x,"$solid must have a non-negative mass")) 
        end 
        length(solids) >= 1 || throw(DomainError(length(solids),"mixtures must contain at least one solid"))
        new(solids)
    end 
end 
Mixture(solids,liquids)=Mixture(solids)









struct Solution <: Composition 
    solids::Dict{Solid,Unitful.Mass} 
    liquids::Dict{Liquid,Unitful.Volume}
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
    solids(::Composition)

access the solids Dict for a composition. 
"""
solids(c::Composition)=c.solids
solids(::Empty)=Dict{Solid,Unitful.Mass}() # Empty doesn't have a solids property


"""
    liquids(::Composition)

access the liquids Dict for a composition
"""
liquids(c::Composition)=c.liquids
liquids(::Empty)=Dict{Liquid,Unitful.Volume}() # Empty doesn't have a liquids property
liquids(c::Mixture)=Dict{Liquid,Unitful.Volume}() # Mixture doesn't have a liquids property


"""
    quantity(::Empty)

returns `missing` for the quantity of an Empty composition
"""
quantity(c::Empty)=missing 

"""
    quantity(::Mixture)

returns the sum of each solid's mass in a Mixture
"""
quantity(c::Mixture)= solids(c) |> values |> sum

"""
    quantity(::Solution)

returns the sum of each liquid's volume in a solution
"""
quantity(c::Solution)= liquids(c) |> values |> sum



 




function Composition(solids,liquids) 
    s=length(solids)
    l=length(liquids)
    if s ==0 && l==0 
        return Empty()
    elseif s >0 && l==0 
        return Mixture(solids)
    elseif l > 0 
        return Solution(solids,liquids)
    else 
        throw(ArgumentError("invalid composition input"))
    end
end 


function chemicals(x::Dict{T,U}) where {T<: Chemical, U}
    
    return collect(keys(x))
end 


# trivial constructors for mixtures and solutions 


function *(quantity::Unitful.Amount,chemical::Solid) 
    return Mixture(Dict(chemical => convert(prefquantunits(chemical),quantity,chemical)))
end 

function *(quantity::Unitful.Mass,chemical::Solid) 
    return Mixture(Dict(chemical => uconvert(prefquantunits(chemical),quantity)))
end

function *(quantity::Unitful.Volume,chemical::Liquid) 
    return Solution(Dict{Solid,Unitful.Mass}(),Dict(chemical=>uconvert(prefquantunits(chemical),quantity)))
end 


function *(num::Number,comp::Composition)
    new_solids=Dict{Solid,Unitful.Mass}()
    new_liquids=Dict{Liquid,Unitful.Volume}()
    for solid in chemicals(solids(comp))
        new_solids[solid]=solids(comp)[solid] * num 
    end 
    for liquid in chemicals(liquids(comp))
        new_liquids[liquid]=liquids(comp)[liquid]*num
    end 
    return Composition(new_solids,new_liquids)
end 

*(comp::Composition,num::Number) = *(num,comp)
/(comp::Composition,num::Number) = *(1/num,comp)



function Base.show(io::IO,::MIME"text/plain",s::Empty;digits::Integer=2)
    printstyled(io, "Empty";bold=true)
end 
function Base.show(io::IO,s::Empty;digits::Integer=2)
    printstyled(io, "Empty";bold=true)
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
function Base.show(io::IO,s::Composition;digits::Integer=2)
    typstr=string(typeof(s))
    if !ismissing(quantity(s))
        printstyled(io,round(quantity(s);digits=digits)," ";bold=true)
    end 
    printstyled(io, "$typstr ($(length(solids(s))+length(liquids(s))) chemical(s))";bold=true)
end 


volume_estimate(c::Composition) = quantity(c)


function volume_estimate(m::Mixture)
    vol=0u"mL"
    sols=solids(m)
    for sol in chemicals(sols)
        q=sols[sol]
        vol+= q/density(sol)
    end 
    return vol
end 


function ==(a::Composition,b::Composition) 
    all([solids(a)==solids(b),liquids(a)==liquids(b)])
end 