struct Culture
    strains::Union{Strain,Vector{Strain}}
    media::Stock
    function Culture(strains,media)
        if strains isa Vector
            allunique(strains) || error("duplicate strains in a culture are not allowed")
        end 
        return new(strains,media)
    end 
end


function Base.show(io::IO,c::Culture)
    printstyled(io, "Culture: ";bold=true)
    if c.strains isa Vector
        for strain in c.strains 
            print(io,strain)
        end 
        print(io, "\n")
    else 
        println(io,c.strains)
    end 
    printstyled(io,"Media: ";bold=true)
    println(io,c.media)
end 


"""
    transfer(donor::Stock,recipient::Stock,quantity::Union{Unitful.Volume,Unitful.Mass})

Transfer a quantity of donor stock to a recipient stock. Generates new stocks. 
"""
function transfer(donor::Culture,recipient::Stock,quantity::Union{Unitful.Volume,Unitful.Mass})

    ustrip(quantity) > 0 || error("culture transfers must have a non-zero quantity")
    transfer_entity=*(donor.media.composition,quantity) 
    donor_media=withdraw(donor.media,transfer_entity)
    recipient_media=deposit(recipient,transfer_entity)
    return Culture(donor.strains,donor_media),Culture(donor.strains,recipient_media)
end 

function transfer(donor::Stock,recipient::Culture,quantity::Union{Unitful.Volume,Unitful.Mass})

    transfer_entity=*(donor.composition,quantity) 
    donor_stock=withdraw(donor,transfer_entity)
    recipient_media=deposit(recipient.media,transfer_entity)
    return donor_stock,Culture(recipient.strains,recipient_media)
end 
function transfer(donor::Culture,recipient::Culture,quantity::Union{Unitful.Volume,Unitful.Mass})

    ustrip(quantity) > 0 || error("culture transfers must have a non-zero quantity")
    transfer_entity=*(donor.media.composition,quantity) 
    donor_media=withdraw(donor.media,transfer_entity)
    recipient_media=deposit(recipient.media,transfer_entity)
    return Culture(donor.strains,donor_media),Culture(union(donor_strains,recipient.strains),recipient_media)
end 

