

struct Container
    name::String 
    capacity::Unitful.Volume # the volume of each well in the container
    shape::Tuple{Int64,Int64} #defines the number and configuration of the wells in the container
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