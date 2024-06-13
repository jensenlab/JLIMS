abstract type Stock end 


struct LiquidStock <: Stock
    id::String 
    composition::Solution
    quantity::Unitful.Volume
    labware::Labware
    isprimary::Bool # primary stocks are purchaesed and arrive straight from the manufacturer without alteration
    function LiquidStock(id,composition,quantity,labware,isprimary)
        typeof(labware.container)==LiquidContainer || error("the selected container is incompatible with a liquid stock")
        labware.container.capacity >= quantity >= 0u"l" || error("volume must be between 0 and $(labware.container.capacity).")
        return new(id,composition,quantity,labware,isprimary)
    end 
end 

LiquidStock(solution,volume,labware) = LiquidStock(id(),solution,volume,labware,false) 

struct SolidStock <: Stock 
    id::String
    composition::Mixture
    quantity::Unitful.Mass
    labware::Labware
    isprimary::Bool # primary stocks are purchased and arrive straight from the manufacturer without alteration 
    function SolidStock(id,composition,quantity,labware,isprimary) 
        labware.container.capacity >= quantity >= 0u"g" || error(" mass must be between 0 and $(labware.container.capacity)")
        typeof(labware.container)==SolidContainer || error("the selected container is incompatible with a solid stock.")
        return new(id,composition,quantity,labware,isprimary)
    end 
end 

SolidStock(solution,volume,labware) = SolidStock(id(),solution,volume,labware,false)

function Stock(id::String, composition::Composition,quantity::Union{Unitful.Mass,Unitful.Volume},labware::Labware,isprimary::Bool)
    if typeof(composition)==Solution && isa(quantity,Unitful.Volume)
        return LiquidStock(id,composition,quantity,labware,isprimary)
    elseif typeof(composition)==Mixture && isa(quantity,Unitful.Mass)
        return SolidStock(id,composition,quantity,labware,isprimary)
    else 
        error("stock composition of type $(typeof(composition)) and quantity of type $(dimension(quantity)) are inconsistent")
    end 
end 

function Stock(composition,quantity,labware)
    return Stock(id(),composition,quantity,labware,false)
end 



#ex stock 
#=
test_stock1=Stock("primary_water_stock",solution["water"],10u"ml",Labware(CON50),1,true)
test_stock2=Stock(x,10u"g",Labware(CON50),1)
=#





"""
    deposit(recipient::Stock,source::CompositionQuantity)

Add a quantity of an untracked source solution or Ingredient to a recipient stock. Generates a new stock if the recipient's composition changes as a result of the deposit.  Helper function for a transfer. 


"""
function deposit(recipient::Stock,source::CompositionQuantity)
    !recipient.isprimary || error("you cannot deposit into primary stocks")
    if recipient.composition == source.composition 
        return Stock(recipient.id,recipient.composition,recipient.quantity+source.quantity,recipient.labware,recipient.isprimary) # update the recipient, but check if the labware can hold the deposit
    else
        a=*(recipient.composition,recipient.quantity)
        res=+(a,source)
        return Stock(res.composition,res.quantity,recipient.labware) #generates a new stock id
    end 
end 





"""
    withdraw(donor::Stock,destination::SolutionVolume)

Remove a quantity of an untracked destination composition from a donor stock. Generates a new stock if the donor's composition changes as a result of the withdrawl. Otherwise, it changes the donor's volume. Helper function for a transfer


"""
function withdraw(donor::Stock,destination::CompositionQuantity)
    if donor.composition ==destination.composition
        return Stock(donor.id,donor.composition,donor.quantity-destination.quantity,donor.labware,donor.isprimary) # update the donor, but check if there is enough to do the withdrawl
    else 
        a=*(donor.composition,donor.quantity) 
        res=-(a,destination) # compute a new composition and quantity 
        return Stock(res.composition,res.quantity,donor.labware) #generates a new stock with a new composition 
    end 
end 


"""
    transfer(donor::Stock,recipient::Stock,quantity::Union{Unitful.Volume,Unitful.Mass})

Transfer a quantity of donor stock to a recipient stock. Generates new stocks. 
"""
function transfer(donor::Stock,recipient::Stock,quantity::Union{Unitful.Volume,Unitful.Mass})
    transfer_entity=*(donor.composition,quantity) 
    donor_out=withdraw(donor,transfer_entity)
    recipient_out=deposit(recipient,transfer_entity)
    return donor_out,recipient_out
end 





