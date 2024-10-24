struct Well 
    id::Integer
    locationid::Integer
    wellindex::Integer
    container::Container
end 



function Base.show(io::IO,w::Well)
    print(io,"Well ID: $(w.id)",",","Labware ID: ",w.locationid," (",w.container,")",", Well ",w.wellindex)
end 


function Base.show(io::IO, ::MIME"text/plain", w::Well)
    println(io, "Well ID: ",w.id)
    println(io,"Location ID: ",w.locationid," (",w.container,")")
    println(io,"Well Index: ",w.wellindex)
end 
#= 
w= Well(
    100,
    "test",
    13,
    WP384,
)
    =#