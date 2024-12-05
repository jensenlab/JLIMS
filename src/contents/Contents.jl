abstract type Contents end 
composition(c::Contents)=c.composition
well(c::Contents)=c.well



struct Stock <: Contents 
    composition::Composition
    well::Well
    function Stock(composition,well) 
        x=volume_estimate(composition)
        if !ismissing(x) # we will not check the capacity if the volume estimate is missing. This occurs for mixtures when we do not have density information about one or more of the solids 
            x <= capacity(well) || throw(DomainError(x,"the stock exceeds the capacity of its well"))
        end 
        new(composition,well)
    end 
end 
strains(::Stock)=Strain[]
Stock(strains,composition,well)=Stock(composition,well)


struct Culture <: Contents 
    strains::Vector{Strain}
    composition::Composition
    well::Well
    function Culture(strains,composition,well) 
        x=volume_estimate(composition)
        if !ismissing(x) # we will not check the capacity if the volume estimate is missing. This occurs for mixtures when we do not have density information about one or more of the solids 
            x <= capacity(well) || throw(DomainError(x,"the culture exceeds the capacity of its well"))
        end 
        allunique(strains) || throw(ArgumentError("all strains must be unique"))
        new(strains,composition,well)
    end 
end 
strains(c::Culture)=c.strains

function Base.convert(::Type{Culture}, x::Stock)
    return Culture([],composition(x),well(x))
end

function Base.promote_rule(x::Type{U},y::Type{T}) where {T <: Stock, U <: Culture}
    return Culture
end 

function Base.in(str::Strain,culture::Culture)
    return str in strains(culture)
end 

function +(a::Contents, c::Composition)
    return typeof(a)(strains(a),composition(a)+c,well(a))
end 
function -(a::Contents,c::Composition)
    return typeof(a)(strains(a),composition(a)-c,well(a)) 
end
function +(a::Contents,s::Vector{Strain})
    out_strs=union(strains(a),s)
        if length(out_strs)==0
            return Stock(composition(a),well(a))
        else
            return Culture(union(strains(a),s),composition(a),well(a))
        end 
end 

function -(a::Contents,s::Vector{Strain})
    strs=setdiff(strains(a),s)
    if length(strs)>0
        return Culture(strs,composition(a),well(a))
    else
        return Stock(composition(a),well(a))
    end 
end 


function +(a::Contents,s::Strain)
    return +(a,[s])
end 

function -(a::Contents,s::Strain)
    return -(a,[s])
end 
 



function withdraw(donor::Contents,quant::Union{Unitful.Volume,Unitful.Mass})
    strs=strains(donor)
    donor_comp=composition(donor)
    q_tot=quantity(donor_comp) 
    factor=quant/q_tot
    comp= factor*donor_comp
    out_donor = donor -comp 
    return out_donor, comp , strs
end 



function transfer(donor::Contents,recipient::Contents,quantity::Union{Unitful.Volume,Unitful.Mass})
    out_donor,comp,strs=withdraw(donor,quantity)
    out_recipient= recipient + comp 
    out_recipient += strs 
    return out_donor,out_recipient 
end 




function Base.show(io::IO,s::Stock)
    printstyled(io,"Stock:\n";bold=true)
    show(io,composition(s))
end 

function Base.show(io::IO,c::Culture)
    strs=strains(culture)
    printstyled(io,"Culture: ($(join(strs,", ")))\n";bold=true)
    show(io,composition(s))

end 








