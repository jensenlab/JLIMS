

"""
    WellCapacityError(vol,cap)

The volume `vol` exceeds the capacity `cap` of its well.

"""
struct WellCapacityError <:Exception
    vol::Any
    cap::Any
 end

function Base.showerror(io::IO, e::WellCapacityError)
    print(io, "Well Capacity Error: ", e.vol ," is greater than the well's capacity (",e.cap,")")
    nothing
end 


"""
    MixingError(chem,msg)

chemical `chem` causes a mixing operation to be invalid
"""
struct MixingError <: Exception
    chem::Any
    msg::Any
end 

function Base.showerror(io::IO,e::MixingError)
    print(io,"Mixing Error with ",e.chem)
    print(io,"\n",e.msg)
    nothing 
end 


"""
    AlreadyLocatedInError

The two locations already share a parent-child relationship
"""
struct AlreadyLocatedInError <: Exception 
end 

function Base.showerror(io::IO,e::AlreadyLocatedInError)
    print(io,"Already-Located-In Error")
end 


"""
    OccupancyError(val,msg)

The movement would overoccupy the parent, with an occupancy `val` greater than 1
"""
struct OccupancyError <: Exception 
    val::Number
    msg::AbstractString 
end 

function Base.showerror(io::IO,e::OccupancyError) 
    print(io,"Occupancy Error: (",e.val,")")
    print(io,"\n",e.msg)
    nothing
end


"""
    LockedLocationError(loc)

The location cannot be moved because it is locked
"""
struct LockedLocationError <: Exception 
    loc::Any
end 

function Base.showerror(io::IO,e::LockedLocationError)
    print(io, "Locked Location Error with: ",e.loc)
    nothing
end 
