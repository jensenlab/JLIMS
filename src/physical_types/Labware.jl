# a piece of labware is a physical instance of a container

struct Labware
    id::String # uuid
    container::Container
    location::Union{Location,Nothing} # labware may have a specified location 
end










