abstract type Contents end 
composition(c::Contents)=c.composition
well(c::Contents)=c.well



struct Stock <: Contents 
    composition::Composition
    well::Well
    function Stock(composition,well) 
        x=volume_estimate(composition)
        if !ismissing(x) # we will not check the capacity if the volume estimate is missing. This occurs for mixtures when we do not have density information about one or more of the solids 
            x <= capacity(well) || throw(WellCapacityError(x,capacity(well)))
        end 
        new(composition,well)
    end 
end 
organisms(::Stock)=Set{Strain}()
Stock(organisms,composition,well)=Stock(composition,well)


struct Culture <: Contents 
    organisms::Set{Strain}
    composition::Composition
    well::Well
    function Culture(organisms,composition,well) 
        x=volume_estimate(composition)
        if !ismissing(x) # we will not check the capacity if the volume estimate is missing. This occurs for mixtures when we do not have density information about one or more of the solids 
            x <= capacity(well) || throw(WellCapacityError(x,capacity(well)))
        end
        new(organisms,composition,well)
    end 
end 
organisms(c::Culture)=c.organisms



function Contents(organisms,composition,well)
    o=length(organisms)
    if o > 0
        return Culture(organisms,composition,well)
    else
        return Stock(composition,well)
    end 
end 

function Base.convert(::Type{Culture}, x::Stock)
    return Culture(Set{Strain}(),composition(x),well(x))
end

function Base.promote_rule(x::Type{U},y::Type{T}) where {T <: Stock, U <: Culture}
    return Culture
end 

function Base.in(str::Strain,culture::Culture)
    return str in organisms(culture)
end 

function +(a::Contents, c::Composition)
    return Contents(organisms(a),composition(a)+c,well(a))
end 
function -(a::Contents,c::Composition)
    return Contents(organisms(a),composition(a)-c,well(a)) 
end
function +(a::Contents,s::Set{Strain})
    orgs=union(organisms(a),s)
    return Contents(orgs,composition(a),well(a))
end 

+(a::Contents,s::Strain) = +(a,Set{Strain}([s]))


function -(a::Contents,s::Set{Strain})
    orgs=setdiff(organisms(a),s)
    return Contents(orgs,composition(a),well(a))
end 


-(a::Contents,s::Strain) =-(a,Set{Strain}([s]))

 

function ==(c1::Contents,c2::Contents)
    return all([organisms(c1)==organisms(c2),composition(c1)==composition(c2),well(c1)==well(c2)])
end 



function withdraw(donor::Contents,quant::Union{Unitful.Volume,Unitful.Mass})
    orgs=organisms(donor)
    donor_comp=composition(donor)
    q_tot=quantity(donor_comp) 
    factor=quant/q_tot
    comp= factor*donor_comp
    out_donor = donor -comp 
    return out_donor, comp , orgs
end 

function deposit(recipient::Contents,comp::Composition,orgs::Set{Strain})
    out_recipient = recipient+ comp 
    out_recipient += orgs
    return out_recipient 
end 
function transfer(donor::Contents,recipient::Contents,quantity::Union{Unitful.Volume,Unitful.Mass})
    out_donor,comp,orgs=withdraw(donor,quantity)
    out_recipient=deposit(recipient,comp,orgs) 
    return out_donor,out_recipient 
end 




function Base.show(io::IO,s::Stock)
    printstyled(io,"Stock:\n";bold=true)
    show(io,composition(s))
end 

function Base.show(io::IO,c::Culture)
    strs=organisms(culture)
    printstyled(io,"Culture: ($(join(strs,", ")))\n";bold=true)
    show(io,composition(s))

end 








