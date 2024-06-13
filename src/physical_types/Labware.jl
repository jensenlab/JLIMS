# a piece of labware is a physical instance of a container

struct Labware
id::String # uuid
container::Container
position::Int64
location::Union{String,Missing} # labware may have a specified location
time::Union{DateTime,Missing} # labware may be timestamped 
function Labware(id,container,position,location,time)
    position in 1:prod(container.shape) || error("position must be a valid position between 1 and $(prod(container.shape)) for a $(container.name)")
    return new(id,container,position,location,time) 
end 
end

Labware(container,position) = Labware(id(),container,position,missing,missing)
Labware(id,container,position)=Labware(id,container,position,missing,missing)








