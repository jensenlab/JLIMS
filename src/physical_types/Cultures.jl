abstract type Culture end 


struct MonoCulture <: Culture
    strains::Strain 
    media::Stock
end 



struct CoCulture <: Culture 
    strains::Vector{Strain}
    media::Stock
    function CoCulture(strains,media)
            allunique(strains) || error("duplicate strains in a culture are not allowed")
        return new(strains,media)
    end 
end

struct EmptyCulture <: Culture 
    strains::Missing 
    media::Stock 
end 

function Culture(strains,media)
    if strains isa Vector
        nonmissing = filter(x-> !ismissing(x),strains)
            if length(nonmissing) == 1
                return MonoCulture(nonmissing[1],media)
            elseif length(nonmissing) > 1 
                return Coculture(nonmissing,media)
            elseif length(nonmissing) == 0 
                return Emptyculture(missing,media)
            end 
    elseif !ismissing(strains)
        return MonoCulture(strains,media)
    else 
        return EmptyCulture(missing,media)
    end 
end 


function Base.show(io::IO,c::Culture)
    printstyled(io, "Culture: ";bold=true)
    if c isa CoCulture
        for i in eachindex(c.strains)
            if i == length(c.strains)
                print(io,c.strains[i])
            else 
                print(io,c.strains[i],", ")
            end 
        end 
    elseif c isa MonoCulture
        print(io,c.strains)
    elseif c isa EmptyCulture
        print(io, "NO ORGANISMS")
    end 
    print(io, "\n")
    printstyled(io,"Media: ";bold=true)
    println(io,c.media)
end 

function Base.convert(T::Type{Culture}, x::Stock)
    return T(missing,x)
end 

function Base.convert(T::Type{U},x::EmptyCulture) where U <:Stock
    return x.media
end 

function Base.promote_rule(x::Type{U},y::Type{T}) where {T <: Stock, U <: Culture}
    return Culture
end 



function well(c::Culture)
    return c.media.well
end 

"""
    transfer(donor::Stock,recipient::Stock,quantity::Union{Unitful.Volume,Unitful.Mass})

Transfer a quantity of donor stock to a recipient stock. Generates new stocks. 
"""
function transfer(donor::T,recipient::U,quantity::Union{Unitful.Volume,Unitful.Mass}) where {T<:Union{Culture,Stock},U<:Union{Culture,Stock}}
    d,r=promote(donor,recipient)
    d1,r1=transfer(d,r,quantity)
    if T isa typeof(Stock)
        d1=convert(T,d1)
    end 
    return d1,r1
end 


function transfer(donor::Culture,recipient::Culture,quantity::Union{Unitful.Volume,Unitful.Mass})

    ustrip(quantity) > 0 || error("culture transfers must have a non-zero quantity")
    transfer_entity=*(donor.media.composition,quantity) 
    donor_media=withdraw(donor.media,transfer_entity)
    recipient_media=deposit(recipient.media,transfer_entity)
    r_out_strains=union(vcat(donor.strains,recipient.strains)) 
    return Culture(donor.strains,donor_media),Culture(r_out_strains,recipient_media)
end 

"""
    deposit(recipient::Culture,source::CompositionQuantity)

Add a quantity of an untracked source solution or Ingredient to a recipient culture. Generates a new media if the recipient's composition changes as a result of the deposit.  Helper function for a transfer. 


"""
function deposit(recipient::Culture,source::CompositionQuantity)
    if recipient.media.composition == source.composition 
        return Culture(recipient.strains,Stock(recipient.media.composition,recipient.media.quantity+source.quantity,recipient.media.well) )# update the recipient, but check if the labware can hold the deposit
    else
        a=*(recipient.media.composition,recipient.media.quantity)
        res=+(a,source)
        return Culture(recipient.strains,Stock(res.composition,res.quantity,recipient.media.well))
    end 
end 







function deposit(recipient::Culture,strain::Strain)
    current = recipient.strains
    if strain in current || strain == current
        return recipient 
    else 
        return Culture(vcat(recipient.strains,strain),recpient.media)
    end 
end 

## cannot withdraw a strain from a culture 