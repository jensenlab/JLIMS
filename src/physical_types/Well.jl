struct Well 
    id::Integer
    labwareid::String
    wellindex::Integer
    container::Container
end 



function Base.show(io::IO,w::Well)
    print(io,"Well ID: $(w.id)",",","Labware ID: ",w.labwareid," (",w.container,")",", Well ",w.wellindex)
end 


function Base.show(io::IO, ::MIME"text/plain", w::Well)
    println(io, "Well ID: ",w.id)
    println(io,"Labware ID: ",w.labwareid," (",w.container,")")
    println(io,"Well ",w.wellindex)
end 
#= 
w= Well(
    100,
    "test",
    13,
    WP384,
)
    =#