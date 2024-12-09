

"""
    can_move_into(parent::Location,child::Location)

returns `true` if child can be moved into parent, and false if not. 

movements that pass `can_move` satisfy four criteria 

1) the child is not locked in its current position. 
2) the child is not already located in the newparent
3) there are no constraints that block the newparent from containing the child
3) the movement would not result in an over-occupancy of the newparent

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







function move_into!(parent::Location,child::Location,lock::Bool=false)
    oldparent=child.parent
    check=can_move_into(parent,child) 
    if !isnothing(oldparent)
        filter!(x->x !== child,oldparent.children)
    end
    push!(parent.children,child)
    child.parent=parent
    if lock 
        lock!(child)
    end 
end 









