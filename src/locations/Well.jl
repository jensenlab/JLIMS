abstract type Well<: Location  end 

AbstractTrees.children(::Well) = ()
capacity(::Well) = 0u"mL"
stock(x::Well)=x.stock


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
        const id::Base.Integer
        const name::Base.String
        parent::Union{JLIMS.Labware,Nothing}
        stock::JLIMS.Stock
        is_locked::Bool
        ($n)(id::Base.Integer,name::Base.String,parent::Union{JLIMS.Labware,Nothing}=nothing,stock::JLIMS.Stock=Empty(),is_locked::Bool=false) = new(id,name,parent,stock,is_locked) 
    end 
    AbstractTrees.ParentLinks(::Type{<:$(n)})=StoredParents()
    JLIMS.capacity(::($n))=$cap
    JLIMS.parent_cost(::($n))=2//1 # occupancy cost is greater than 1. The value of 2//1 was chosen arbitrarily the new location is not allowed to be a parent unless otherwise specified
    JLIMS.child_cost(::($n))=2//1 # occupancy cost is greater than 1. The value of 2//1 was chosen arbitrarily.  The new location is not allowed to be a child unless otherwise specified


    end)
end


function Base.show(io::IO,w::Well)
    print(io,name(w))
end 


function empty!(x::Well)
    x.stock=Empty()
end 

function empty(x)
    y=deepcopy(x)
    empty!(y)
    return y
end 
    

function sterilize!(x::Well)
    st=stock(x)
    st_new=Stock(Set{Strain}(),solids(st),liquids(st))
    x.stock=st_new
end 

function sterilize(x)
    y=deepcopy(x)
    sterilize!(y)
    return y
end 



function withdraw!(donor::Well,quant::Union{Unitful.Volume,Unitful.Mass})
    st=stock(donor)
    q_tot=quantity(st) 
    factor=quant/q_tot
    st_out= factor*st
    donor.stock=st-st_out  
    return st_out
end 

function deposit!(recipient::Well,trf_stock::Stock)
    st=stock(recipient)
    recipient.stock=st+trf_stock
end 
function transfer!(donor::Well,recipient::Well,quantity::Union{Unitful.Volume,Unitful.Mass})
    trf_stock=withdraw!(donor,quantity)
    deposit!(recipient,trf_stock) 
end 


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