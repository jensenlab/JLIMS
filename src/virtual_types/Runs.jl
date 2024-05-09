

struct Run 
    id::String 
    labware::Labware
    position::Integer
    controls::Vector{String}
    blanks::Vector{String}
    Run(id,labware,position,controls,blanks)= position in 1:prod(labware.container.shape) ? new(id,labware,position,controls,blanks) : error("position must be a valid position between 1 and $(prod(labware.container.shape))") 
end 




