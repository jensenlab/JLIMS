
"""
    abstract type Well<: Location  end

Wells are special [`Location`](@ref) subtypes that contain a single [`Stock`](@ref) object. 

Wells are only allowed to be located in [`Labware`] objects and cannot be moved from the labware. They are physically tied to a Labware. 
"""
mutable struct Well{N} <: Location 
    const location_id::Base.Integer
    const name::Base.String
    parent::Union{JLIMS.Labware,Nothing}
    stock::JLIMS.Stock
    attributes::AttributeDict
    cost::Real
    is_active::Bool
    function Well{N}(id::Base.Integer,name::Base.String,parent=nothing,stock=Empty(),attributes=AttributeDict(),cost::Real=0,is_active::Bool=true) where N
        cap=wellcapacity(Well{N})
        (JLIMS.volume_estimate(stock) <= cap) || throw(WellCapacityError(JLIMS.volume_estimate(stock),cap))
        new(id,name,parent,stock,attributes,cost,is_active) 
    end 
end 


AbstractTrees.ParentLinks(::Type{<:Well})=StoredParents()
parent_cost(::Well)=2//1 # occupancy cost is greater than 1. The value of 2//1 was chosen arbitrarily the new location is not allowed to be a parent unless otherwise specified
child_cost(::Well)=2//1 # occupancy cost is greater than 1. The value of 2//1 was chosen arbitrarily.  The new location is not allowed to be a child unless otherwise specified


"""
    wellcapacity(::Type{<:Labware}) 

Return the capacity of the each well in a labware as a Unitful.Volume quantity

Well types defined by the [`@labware`](@ref) macro overload `wellcapacity` to provide a method for that specific type.
""" 
function wellcapacity(::Type{Well{N}}) where N 
    return N * u"µL"
end 

function wellcapacity(w::Well) 
    return wellcapacity(typeof(w))
end 


AbstractTrees.children(::Well) = ()



"""
    stock(::Well)

Access the [`Stock`](@ref) property of a well
"""
stock(x::Well)=x.stock

# all wells are always locked
is_locked(::Well)=true


""" 
    cost(::Well)

Access the cost property of a well

"""
cost(x::Well) = x.cost


occupancy(::Well) = 1//1


function check_capacity(s::Stock,w::Well) 
    a=volume_estimate(s)
    b=wellcapacity(w)
    a <= b || throw(WellCapacityError(a,b))
    nothing
end 

function Base.show(io::IO,w::Well)
    print(io,name(w))
end 

function lock!(::Well)
end 

function unlock!(::Well)
end

function toggle_lock!(::Well)
end




"""
    empty!(x::Well)

Remove the stock contained in a well by setting it to `Empty()`

See also: [`empty`](@ref), [`Empty`](@ref)
"""
function empty!(x::Well)
    s=Empty()
    check_capacity(s,x)
    x.stock=s
    nothing
end 

"""
    empty(x::Well)

Create a copy of well `x` and Remove the stock contained in the well by setting it to `Empty()`

See also: [`empty!`](@ref), [`Empty`](@ref)
"""
function empty(x)
    y=deepcopy(x)
    empty!(y)
    return y
end 
    

"""
    sterilize!(x::Well)

Remove any organisms from the [`Stock`](@ref) object contained in well `x`

See also [`sterilise`](@ref)
"""
function sterilize!(x::Well)
    st=stock(x);
    st_new=Stock(Set{Organism}(),solids(st),liquids(st));
    check_capacity(st_new,x)
    x.stock=st_new;
    nothing
end 


"""
    sterilize(x::Well)

Create a copy of well `x` and Remove any organisms from the [`Stock`](@ref) object contained in the well

See also: [`sterilize!`](@ref)
"""
function sterilize(x)
    y=deepcopy(x);
    sterilize!(y);
    return y
end 

"""
    drain!(x::Well)

Remove all [`Chemical`](@ref) components from the [`Stock`](@ref) object contained in the well. 

* `drain!` leaves behind any [`Organism`](@ref)s * 

See also: [`drain`](@ref),[`sterilize!`](@ref),[`empty!`](@ref)
"""
function drain!(x::Well)
    st=stock(x);
    st_new=Stock(organisms(st),SolidDict(),LiquidDict())
    check_capacity(st_new,x)
    x.stock=st_new;
    nothing 
end 

"""
    drain(x::Well)

Create a copy of `well` x and Remove all [`Chemical`](@ref) components from the [`Stock`](@ref) object contained in the well. 

* `drain` leaves behind any [`Organism`](@ref)s * 

See also: [`drain!`](@ref),[`sterilize`](@ref),[`empty`](@ref)
"""
function drain(x::Well)
    y=deepcopy(x)
    drain!(y);
    return y
end 



function withdraw!(donor::Well,quant::Union{Unitful.Volume,Unitful.Mass})
    st=stock(donor)
    q_tot=quantity(st) 
    Unitful.dimension(q_tot) == Unitful.dimension(quant) || error("the withdrawl quantity dimension must be the same as the well's stock dimension")
    factor=Unitful.uconvert(NoUnits,quant/q_tot)
    st_out= factor*st
    donor.stock=st-st_out 
    transfer_cost=factor*cost(donor)
    donor.cost -= transfer_cost 
    return st_out, transfer_cost
end 

function deposit!(recipient::Well,trf_stock::Stock,trf_cost::Real)
    st=stock(recipient)
    new_stock=st+trf_stock
    check_capacity(new_stock,recipient)
    recipient.stock=new_stock
    recipient.cost += trf_cost
    nothing
end 

"""
    transfer!(donor::Well,recipient::Well,quantity::Union{Unitful.Volume,Unitful.Mass})

Remove `quantity` from `donor` and move it to `recipient` 

`transfer!` mutates the donor and recipient in place. 

See also: [`transfer`](@ref)
"""
function transfer!(donor::Well,recipient::Well,quantity::Union{Unitful.Volume,Unitful.Mass},configuration::String="")
    trf_stock,trf_cost=withdraw!(donor,quantity)
    deposit!(recipient,trf_stock,trf_cost) 
    nothing
end 

"""
    transfer(donor::Well,recipient::Well,quantity::Union{Unitful.Volume,Unitful.Mass})

Remove `quantity` from `donor` and move it to `recipient` 

`transfer` copies the donor and recipient and returns the updated donor and recipient as new objects.

See also: [`transfer!`](@ref)
"""
function transfer(donor,recipient,quantity,configuration::String="")
    d=deepcopy(donor)
    r=deepcopy(recipient)
    transfer!(d,r,quantity,configuration)
    return d,r
end 
#=






function Base.show(io::IO, ::MIME"text/plain", w::Well)
    println(io, "Well ID: ",w.id)
    println(io,"Location ID: ",w.locationid," (",w.container,")")
    println(io,"Well Index: ",w.wellindex)
end 

=#
#= 
w= Well(
    100,
    "test",
    13,
    WP384,
)
    =#