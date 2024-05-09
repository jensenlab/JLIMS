# a piece of labware is a physical instance of a container

struct Labware
id::String # uuid
container::Container
location::Union{String,Missing} # labware may have a specified location
time::Union{DateTime,Missing} # labware may be timestamped 
end

Labware(container) = Labware(id(),container,missing,missing)
Labware(id,container)=Labware(id,container,missing,missing)








