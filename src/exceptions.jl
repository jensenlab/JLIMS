struct CapacityError <:Exception
    msg::AbstractString
    vol::Unitful.Volume
 end

Base.showerror(io::IO, e::CapacityError) = print(io::IO, e.vol, e.msg)

struct MixingError <: Exception
    chem::Chemical
    msg::AbstractString
end 

Base.showerror(io::IO,e::MixingError)= print(io,e.chem,e.msg)


struct SummationError <: Exception 
    val::Any 
    msg::AbstractString
end 

Base.showerror(io::IO,e::SummationError)= print(io,e.val,e.msg)


struct AlreadyLocatedInError <: Exception 
    msg::AbstractString
end 

Base.showerror(io::IO,e::AlreadyLocatedInError)=print(io,e.msg)

struct OccupancyError <: Exception 
    val::Number
    msg::AbstractString 
end 

Base.showerror(io::IO,e::OccupancyError) = print(io,e.val,e.msg)
