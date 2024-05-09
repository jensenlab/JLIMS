struct Container
    name::String 
    volume::Unitful.Volume
    shape::Tuple{Int64,Int64}
    vendor::String 
    catalog::String 
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