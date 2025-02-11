

"""
    can_move_into(parent::Location,child::Location)

returns `true` if child can be moved into parent, throw an error if not

there are three errors that prevent movement 

1) [`LockedLocationError`](@ref): `child` is locked in its current parent.  
2) [`AlreadyLocatedInError`](@ref): `child` is already located in `parent`
3) [`OccupancyError`](@ref): `parent` has occupancy constraints that prevent it from containing `child`. This could happen if `parent` is full or if `child` is never meant to be able to fit inside `parent`. 

See also: [`move_into`](@ref)
"""
function can_move_into(newparent::Location,child::Location)
        if is_locked(child)
                throw(LockedLocationError(child))
        end 

        if AbstractTrees.ischild(child,newparent)
                throw(AlreadyLocatedInError())  #the child is already located in parent 
        end 
        occ_cost = occupancy_cost(newparent,child)
        current= occupancy(newparent)
        if current + occ_cost <= 1//1 
            return true  # movement is allowed! 
        else 
            throw(OccupancyError(current+occ_cost,"movement would overoccupy parent")) # movement would overfill the parent, we block the movement 
        end 
end 



function remove!(parent::Location,child::Location)
    filter!(x->x !== child,parent.children)
    return nothing 
end 
function remove!(parent::Location,child::LocationRef)
    filter!(x->x !== child,parent.children)
    return nothing 
end 

function add_to!(parent::Location,child::Location)
    check=can_move_into(parent,child) 
    push!(parent.children,child)
    child.parent=parent
    return nothing 
end 

function add_to!(parent::Location,child::LocationRef)
    push!(parent.children,child)
    return nothing 
end 

function add_to!(parent::Nothing,child::Location)
    child.parent=nothing 
    return nothing 
end 



"""
    move_into!(parent::Location,child::Location,lock::Bool=false)

Move `child` into `parent`, if allowed. 

if `lock=true`, then also lock the child after the movement. 
"""
function move_into!(parent::Union{Location,Nothing},child::Location,lock::Bool=false)
    oldparent=child.parent
    add_to!(parent,child)
    if !isnothing(oldparent)
        remove!(oldparent,child)
    end
    if lock 
        lock!(child)
    end 
end 


function move_into(parent::Union{Location,Nothing},child::Location,lock::Bool=false)
    p=deepcopy(parent)
    c=deepcopy(child)
    move_into!(p,c,lock)
    return p,c
end 







