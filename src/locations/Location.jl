
"""
    abstract type Location end

Locations represent the physical objects that make up the lab. `Location` objects use the [AbstractTrees.jl](https://juliacollections.github.io/AbstractTrees.jl/stable/) interface to construct relational hierarchies.

See also: [`@location`](@ref)
"""
abstract type Location end 

AbstractTrees.children(x::Location) = x.children
AbstractTrees.parent(x::Location) =x.parent
AbstractTrees.nodevalue(x::Location)=location_id(x)
AbstractTrees.ParentLinks(::Type{<:Location})=StoredParent()

stock(::Location)=Empty()
"""
    location_id(x::Location)

Access the `location_id` property of a location.
"""
location_id(x::Location)=x.location_id


"""
    shape(x::Location)
Access the `shape` property, if defined, of a location. 
"""
shape(x::Location)=nothing 
"""
    vendor(x::Location)
Access the `vendor` property, if defined, of a location.
"""
vendor(x::Location)=nothing
"""
    catalog(x::Location)
Access the `catalog` poperty, if defined, of a location.
"""
catalog(x::Location)=nothing

"""
    name(x::Location)
Access the `name` property of a location. The name of a location does not need to be unique and can be used for display purposes. 
"""
name(x::Location)=x.name

"""
    attributes(x::Location)
Access the `attributes` property of a location. 
"""
attributes(x::Location)=x.attributes    
"""
    is_locked(x::Location)

Access the state of the `is_locked` property of a location. Locked locations cannot be moved from their current parent, but *children of locked locations can be moved*. 

See also: [`unlock!`](@ref),[`lock!`](@ref),[`toggle_lock!`](@ref),[`unlock`](@ref),[`lock`](@ref),[`toggle_lock`](@ref).
"""
is_locked(x::Location)=x.is_locked # locked locations cannot be moved from their current parent. Children of locked locations CAN be moved. 

"""
    unlock!(x::Location)
Change the state of the `is_locked` property of a location to `false`.

See also: [`is_locked`](@ref),[`unlock`](@ref).
"""
function unlock!(x::Location)
    x.is_locked=false
end 
"""
    unlock(x::Location)
Create a copy of Location `x` and change the `is_locked` property to `false`. 

See also: [`is_locked`](@ref),[`unlock!`](@ref).
"""
function unlock(x::Location)
    y=deepcopy(x)
    unlock!(y)
    return y 
end 

"""
    lock!(x::Location)
Change the state of the `is_locked` property of a location to `true`.

See also: [`is_locked`](@ref),[`lock`](@ref).
"""
function lock!(x::Location)
    x.is_locked=true
end
"""
    lock(x::Location)

Create a copy of Location `x` and change the `is_locked` property to `true`. 

See also: [`is_locked`](@ref),[`lock!`](@ref).
"""
function lock(x::Location)
    y=deepcopy(x)
    lock!(y)
    return y
end 

"""
    toggle_lock!(x:Location)

Flip the state of the `is_locked` property of a location.

See also: [`is_locked`](@ref),[`toggle_lock`](@ref).
"""
function toggle_lock!(x::Location)
    x.is_locked=!is_locked(x)
end 


"""
    toggle_lock(x::Location)

Create a copy of Location `x` and flip the state of its `is_locked` peroperty

See also: [`is_locked`](@ref),[`toggle_lock!`](@ref).
"""
function toggle_lock(x::Location)
    y=deepcopy(x)
    toggle!(y)
    return y
end 

"""
    is_active(x::Location)

Access the `is_active` property of a location


See also: [`activate!`](@ref), [`deactivate!`](@ref), [`toggle_activity!`](@ref)
"""
function is_active(x::Location)
    return x.is_active
end 


"""
    activate!(x::Location)

Set the `is_active` property of [`Location`](@ref) `x` to `true`

See also: [`is_active`](@ref), [`activate`](@ref)
"""
function activate!(x::Location)
    x.is_active=true
end 
"""
    deactivate!(x::Location)

Set the `is_active` property of [`Location`](@ref) `x` to `false`

See also: [`is_active`](@ref), [`deactivate`](@ref)
"""
function deactivate!(x::Location)
    x.is_active=false
end 

"""
    toggle_activity!(x::Location)

Switch the `is_active` property of [`Location`](@ref) `x` from its current state.

See also: [`is_active`](@ref), [`toggle_activity`](@ref)
"""
function toggle_activity!(x::Location)
    x.is_active=!is_active(x)
end 
"""
    activate!(x::Location)

Copy [`Location`](@ref) `x` and Set the `is_active` property of the copy to `true`

See also: [`is_active`](@ref), [`activate!`](@ref)
"""
function activate(x::Location)
    y=deepcopy(x)
    return activate!(y)
end 
"""
    deactivate!(x::Location)

Copy [`Location`](@ref) `x` and Set the `is_active` property of the copy to `false`

See also: [`is_active`](@ref), [`deactivate!`](@ref)
"""
function deactivate(x::Location)
    y=deepcopy(x)
    return deactivate!(y)
end 
"""
    toggle_activity!(x::Location)

Copy [`Location`](@ref) `x` and Switch the `is_active` property of the copy from its current state.

See also: [`is_active`](@ref), [`toggle_activity!`](@ref)
"""
function toggle_activity(x::Location)
    y=deepcopy(x)
    return toggle_activity!(y)
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




"""
    macro location(name,constrained_as_parent=false,constrained_as_child=false)

Create a new Type `name` that is a [`Location`](@ref) subtype. 

The `constrained_as_parent` flag indicates that `name` will be unable to be a parent by defualt.
The `constrained_as_child` flag indicates that `name` will be unable to be a child by defualt.  
"""
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
        parent::Union{JLIMS.Location,Nothing,JLIMS.LocationRef}
        children::Vector{T} where T<:Union{JLIMS.Location,JLIMS.LocationRef}
        attributes::AttributeDict
        is_locked::Bool
        is_active::Bool
        ($n)(id::Base.Integer,name::Base.String,parent=nothing,children=JLIMS.Location[],attributes=AttributeDict(),is_locked::Bool=false,is_active::Bool=true) = new(id,name,parent,children,attributes,is_locked,is_active) 
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



"""
    ancestors(x::Location;rev=false)

return the parent location chain of location `x` in the order of most to least proximal. 

Use the keyword arg `rev=true` to reverse the order from least proximal to most proximal
"""
function ancestors(x::Location;rev=false)
    out=Location[]
    node=deepcopy(x)
    while !AbstractTrees.isroot(node)
        push!(out,node);
        node=AbstractTrees.parent(node);
    end 
    push!(out,node);
    if rev
        return reverse(out)
    else
        return out
    end 
end 
       

"""
    environment(x::Location)
Compute the environmental attributes of location `x`. 

Going down the chain of ancestors from least proximal to most proximal, overwrite any attributes with a more proximal value for each attribute.

"""
function environment(x::Location)
    out=AttributeDict()
    ancestry =ancestors(x;rev=true)
    for ancestor in ancestry
        attrs=attributes(ancestor)
        for attr in values(attrs) 
        set_attribute!(out,attr)
        end 
    end 
    return out 
end 




function Base.show(io::IO,x::Location)
    print(io,name(x))
end 

""" 
    set_attribute!(x::Location,attribute::Attribute)

Set the value for a location's environmental attributes to `attribute`. 

We use this method to ensure a proper pairing between the attribute type and the attribute in the dict.
"""
function set_attribute!(loc::Location,attribute::Attribute)
    set_attribute!(attributes(loc),attribute) 
    nothing 
end 

""" 
    set_attribute(dict::Location,attribute::Attribute)

Create a copy of `loc` and set it's environmental attributes to attribute
"""
function set_attribute(loc::Location,attribute::Attribute)
    y=deepcopy(loc)
    set_attribute!(y,attribute) 
    return y 
end 