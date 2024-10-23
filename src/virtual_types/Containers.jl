"""
    Container(name,capacity,shape)

Define a new type of JLIMS labware 

"""
struct Container
    name::String 
    capacity::Unitful.Volume # the volume of each well in the container
    shape::Tuple{Int64,Int64} #defines the number and configuration of the wells in the container
end 


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