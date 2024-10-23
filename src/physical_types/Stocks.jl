abstract type Stock end 


tolerance=1.001

struct LiquidStock <: Stock
    composition::Solution
    quantity::Unitful.Volume
    well::Well
    function LiquidStock(composition,quantity,well)
        tolerance*well.container.capacity >= quantity >= 0u"l" || throw(CapacityError("Well $(well.id) -> $(quantity)) stock must be between 0 and $(well.container.capacity).", quantity))
        return new(composition,quantity,well)
    end 
end 


struct SolidStock <: Stock 
    composition::Mixture
    quantity::Unitful.Mass
    well::Well 
    function SolidStock(composition,quantity,well) 
        density_estimate=mixture_density(composition)
        estimated_volume=0
        typeof(density_estimate)==Missing || density_estimate==0u"ml" ? estimated_volume=0u"ml" : estimated_volume=quantity/density_estimate
        tolerance*well.container.capacity >= estimated_volume >= 0u"ml" || throw(CapacityError("Well $(well.id) -> $(estimated_volume)) stock must be between 0 and $(well.container.capacity).", estimated_volume))
        return new(composition,quantity,well)
    end 
end 

struct EmptyStock <: Stock 
    composition::Empty 
    quantity::Missing 
    well::Well
end 



function Stock(composition::Composition,quantity::Union{Unitful.Mass,Unitful.Volume,Missing},well::Well)
    if typeof(composition)==Solution && isa(quantity,Unitful.Volume)
        return LiquidStock(composition,quantity,well)
    elseif typeof(composition)==Mixture && isa(quantity,Unitful.Mass)
        return SolidStock(composition,quantity,well)
    elseif typeof(composition)==Empty && isa(quantity,Missing)
        return EmptyStock(composition,quantity,well)
    else 
        error("stock composition of type $(typeof(composition)) and quantity of type $(dimension(quantity)) are inconsistent")
    end 
end 


function Base.show(io::IO,s::Stock)
    
    printstyled(io,round(s.quantity;digits=3), " ";bold=true)
    println(io,s.composition)
    println(io,s.well)
end 

function Base.show(io::IO,::MIME"text/plain",s::Stock)
    if !ismissing(s.quantity)
        printstyled(io,round(s.quantity;digits=3), " ";bold=true)
    end 
    println(io,s.composition)
    println(io , s.well)
end 








"""
    deposit(recipient::Stock,source::CompositionQuantity)

Add a quantity of an untracked source solution or Ingredient to a recipient stock. Generates a new stock if the recipient's composition changes as a result of the deposit.  Helper function for a transfer. 


"""
function deposit(recipient::Stock,source::CompositionQuantity)
    if recipient.composition == source.composition 
        return Stock(recipient.composition,recipient.quantity+source.quantity,recipient.well) # update the recipient, but check if the labware can hold the deposit
    else
        a=*(recipient.composition,recipient.quantity)
        res=+(a,source)
        return Stock(res.composition,res.quantity,recipient.well) #generates a new stock id
    end 
end 





"""
    withdraw(donor::Stock,destination::SolutionVolume)

Remove a quantity of an untracked destination composition from a donor stock. Generates a new stock if the donor's composition changes as a result of the withdrawl. Otherwise, it changes the donor's volume. Helper function for a transfer


"""
function withdraw(donor::Stock,destination::CompositionQuantity)
    if donor.composition ==destination.composition
        return Stock(donor.composition,donor.quantity-destination.quantity,donor.well) # update the donor, but check if there is enough to do the withdrawl
    else 
        a=*(donor.composition,donor.quantity) 
        res=-(a,destination) # compute a new composition and quantity 
        return Stock(res.composition,res.quantity,donor.well) #generates a new stock with a new composition 
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





