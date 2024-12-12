
"""
    abstract type Well<: Location  end

Wells are special [`Location`](@ref) subtypes that contain a single [`Stock`](@ref) object. 

Wells are only allowed to be located in [`Labware`] objects and cannot be moved from the labware. They are physically tied to a Labware. 
"""
abstract type Well<: Location  end 

AbstractTrees.children(::Well) = ()
"""
    capacity(::Well) 

Return the capacity of the well as a Unitful.Volume quantity

Well types defined by the [`@well`](@ref) macro overload `capacity` to provide a method for that specific type.
""" 
capacity(::Well) = 0u"mL"

"""
    stock(::Well)

Access the [`Stock`](@ref) property of a well
"""
stock(x::Well)=x.stock

# all wells are always locked
is_locked(::Well)=true


"""
    @well name capacity

Define a new well type `name` with capacity `capacity` 

See also: [`Well`](@ref),[`capacity`](@ref)
"""

occupancy(::Well) = 1//1
macro well(name,capacity)
    n=Symbol(name)
    cap::Unitful.Volume=eval(capacity)

    if isdefined(__module__,n) || isdefined(JLIMS,n)
        throw(ArgumentError("Well type $n already exists"))
    end 

    return esc(quote
    import JLIMS: occupancy_cost,parent_cost,child_cost
    import AbstractTrees: ParentLinks
    export $n, occupancy_cost
    mutable struct $n <: (JLIMS.Well)
        const location_id::Base.Integer
        const name::Base.String
        parent::Union{JLIMS.Labware,Nothing}
        stock::JLIMS.Stock
        attributes::AttributeDict
        function ($n)(id::Base.Integer,name::Base.String,parent::Union{JLIMS.Labware,Nothing}=nothing,stock::JLIMS.Stock=Empty(),attributes::AttributeDict=AttributeDict()) 
            (JLIMS.volume_estimate(stock) <= $cap) || throw(WellCapacityError(JLIMS.volume_estimate(stock),$cap))
            new(id,name,parent,stock,attributes) 
        end 
    end 
    AbstractTrees.ParentLinks(::Type{<:$(n)})=StoredParents()
    JLIMS.capacity(::($n))=$cap
    JLIMS.parent_cost(::($n))=2//1 # occupancy cost is greater than 1. The value of 2//1 was chosen arbitrarily the new location is not allowed to be a parent unless otherwise specified
    JLIMS.child_cost(::($n))=2//1 # occupancy cost is greater than 1. The value of 2//1 was chosen arbitrarily.  The new location is not allowed to be a child unless otherwise specified


    end)
end


function check_capacity(s::Stock,w::Well) 
    a=volume_estimate(s)
    b=capacity(w)
    a <= b || throw(WellCapacityError(a,b))
    nothing
end 

function Base.show(io::IO,w::Well)
    print(io,name(w))
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
    st_new=Stock(Set{Strain}(),solids(st),liquids(st));
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

* `drain!` leaves behind any [`Strain`](@ref)s * 

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

* `drain` leaves behind any [`Strain`](@ref)s * 

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
    factor=quant/q_tot
    st_out= factor*st
    donor.stock=st-st_out  
    return st_out
end 

function deposit!(recipient::Well,trf_stock::Stock)
    st=stock(recipient)
    new_stock=st+trf_stock
    check_capacity(new_stock,recipient)
    recipient.stock=new_stock
    nothing
end 

"""
    transfer!(donor::Well,recipient::Well,quantity::Union{Unitful.Volume,Unitful.Mass})

Remove `quantity` from `donor` and move it to `recipient` 

`transfer!` mutates the donor and recipient in place. 

See also: [`transfer`](@ref)
"""
function transfer!(donor::Well,recipient::Well,quantity::Union{Unitful.Volume,Unitful.Mass})
    trf_stock=withdraw!(donor,quantity)
    deposit!(recipient,trf_stock) 
    nothing
end 

"""
    transfer(donor::Well,recipient::Well,quantity::Union{Unitful.Volume,Unitful.Mass})

Remove `quantity` from `donor` and move it to `recipient` 

`transfer` copies the donor and recipient and returns the updated donor and recipient as new objects.

See also: [`transfer!`](@ref)
"""
function transfer(donor,recipient,quantity)
    d=deepcopy(donor)
    r=deepcopy(recipient)
    transfer!(d,r,quantity)
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