abstract type Container end 

struct LiquidContainer <: Container
    name::String 
    capacity::Unitful.Volume
    shape::Tuple{Int64,Int64}
    vendor::String 
    catalog::String 
end 

struct SolidContainer <:Container
    name::String
    capacity::Unitful.Mass
    shape::Tuple{Int64,Int64}
    vendor::String
    catalog::String
end 



function Container(name::String,capacity::Union{Unitful.Volume,Unitful.Mass},shape::Tuple{Int64,Int64},vendor::String,catalog::String)

    if isa(capacity,Unitful.Volume)
        return LiquidContainer(name,capacity,shape,vendor,catalog)
    else
        return SolidContainer(name,capacity,shape,vendor,catalog)
    end 

end 



#=
WP384=Container(
    "WP384",
    80u"µl",
    (16,24),
    "Corning",
    "TBD"

)


CON50=Container(
    "CON50",
    50u"mL",
    (1,1),
    "TBD",
    "TBD"
)
=#