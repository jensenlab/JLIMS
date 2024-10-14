struct CapacityError <:Exception
    msg::AbstractString
    vol::Unitful.Volume
 end

Base.showerror(io,::IO, e::CapacityError) = print(io::IO,e.msg)

