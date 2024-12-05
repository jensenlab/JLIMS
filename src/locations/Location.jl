
abstract type Location end 



location_id(x::Location)=x.location_id
AbstractTrees.children(x::Location) = x.children
AbstractTrees.parent(x::Location) =x.parent
AbstractTrees.nodevalue(x::Location)=location_id(x)
AbstractTrees.ParentLinks(::Type{<:Location})=StoredParent()
shape(x::Location)=nothing 
vendor(x::Location)=nothing
catalog(x::Location)=nothing

name(x::Location)=x.name
is_locked(x::Location)=x.is_locked # locked locations cannot be moved from their current parent. Children of locked locations CAN be moved. 

function unlock!(x::Location)
    x.is_locked=false
end 

function lock!(x::Location)
    x.is_locked=true
end
function toggle!(x::Location)
    x.is_locked=!x.is_locked
end 


parent_cost(::Location)=0//1
child_cost(::Location)=0//1


"""
    occupancy_cost(x::Location,y::Location)

Returns a Rational representing the fractional occupancy of child in parent. We take the max of the three cost types.

"""
occupancy_cost(parent::Location,child::Location) = max(parent_cost(parent),child_cost(child)) # by default,we check for parent and child cost constraints, and take the max, otherwise, we define a specific method for the pair.


macro occupancy_cost(parent, child, occupancy)
    p=Symbol(parent)
    c=Symbol(child)
    occ =eval(occupancy)
    if !(occ isa Rational)
        throw(ArgumentError("Occupancy must be a Rational datatype"))
    end 

    if !isdefined(__module__,p) && !isdefined(JLIMS,p)
        throw(ArgumentError("Parent Location type $p is undefined"))
    end 
    if !isdefined(__module__,c) && !isdefined(JLIMS,c)
        throw(ArgumentError("Child Location type $c is undefined"))
    end 

    return esc(quote 
        import JLIMS: occupancy_cost
        JLIMS.occupancy_cost(parent::$p , child::$c) = $occ;
    end 
    )
end 



"""
    occupancy(x::Location)

return the fractional occupancy of location x. 

Occupancies can range from 0 (empty) to 1 (fully occupied). 

The occupancy is calculated by summing the `occupancy_cost` of each child in the location.

"""
function occupancy(x::Location)
    occ=0//1
    
    for child in children(x) 
            occ += occupancy_cost(x,child)
    end
    return occ 
end 





macro location(name,constrained_as_parent=false,constrained_as_child=false)
    n=Symbol(name)
    p_constraint::Bool=eval(constrained_as_parent)
    c_constraint::Bool=eval(constrained_as_child)

    if isdefined(__module__,n) || isdefined(JLIMS,n)
        throw(ArgumentError("Location type $n already exists"))
    end 

    return esc(quote
    import JLIMS: parent_cost,child_cost
    import AbstractTrees: ParentLinks
    export $n
    mutable struct $n <: (JLIMS.Location)
        const location_id::Base.Integer
        const name::Base.String
        parent::Union{JLIMS.Location,Nothing}
        children::Vector{T} where T<:JLIMS.Location
        is_locked::Bool
        ($n)(id::Base.Integer,name::Base.String,parent::Union{JLIMS.Location,Nothing}=nothing,children=JLIMS.Location[],is_locked::Bool=false) = new(id,name,parent,children,is_locked) 
    end 
    AbstractTrees.ParentLinks(::Type{<:($n)})=AbstractTrees.StoredParents()
    if $p_constraint
        JLIMS.parent_cost(::($n))=2//1 # occupancy cost is greater than 1. The value of 2//1 was chosen arbitrarily the new location is not allowed to be a parent unless otherwise specified
    end 
    if $c_constraint
        JLIMS.child_cost(::($n))=2//1 # occupancy cost is greater than 1. The value of 2//1 was chosen arbitrarily.  The new location is not allowed to be a child unless otherwise specified
    end

    end)
end


function ancestors(x::Location)
    out=Location[]
    node=deepcopy(x)
    while !AbstractTrees.isroot(node)
        push!(out,node)
        node=AbstractTrees.parent(node)
    end 
    push!(out,node)
    return reverse(out) 
end 
       



function Base.show(io::IO,x::Location)
    print(name(x))
end 



#=
function Base.show(io::IO,c::Container)
    print(io, c.name," => ",c.capacity," ($(c.shape[1]) by $(c.shape[2]))")
end

function Base.show(io::IO, ::MIME"text/plain", c::Container)
    println(io, c.name)
    println(io,"Well Capacity: $(c.capacity)")
    row="rows"
    col="columns"
    if c.shape[1]==1
        row="row"
    end 
    if c.shape[2]==1
        col="column"
    end
    println(io, "$(c.shape[1]) $row by $(c.shape[2]) $col")
end 

=#




#=
WP384=Container(
    "WP384",
    80u"µl",
    (16,24)

)


CON50=Container(
    "CON50",
    50u"mL",
    (1,1)
)
=#