module JLIMS

using 
    Unitful,
    UnitfulParsableString,
    #CSV,
    #DataFrames,
    AbstractTrees,
    HTTP, # chemical parsing only
    JSON, # chemical parsing only 
    UUIDs # used for generating labware name
import Base: +,-,*,/,convert, show ,sort , promote_rule,round , in, == # all overloaded by this package
import AbstractTrees: children,parent,nodevalue

include("./Units/JensenLabUnits.jl")

    using .JensenLabUnits
    Unitful.register(JensenLabUnits)

Unitful.promote_unit(::S,::T) where {S<:Unitful.VolumeUnits,T<:Unitful.VolumeUnits} = u"mL"
Unitful.promote_unit(::S,::T) where {S<:Unitful.MassUnits,T<:Unitful.MassUnits} = u"g" 
include("./exceptions.jl")
include("./locations/Location.jl")
include("./locations/Labware.jl")
include("./locations/Well.jl")


include("./contents/Chemicals.jl")

include("./contents/Strains.jl")
include("./contents/Compositions.jl")
include("./contents/chemical_parsing.jl")
include("./contents/Contents.jl")
include("./operations/movement.jl")
include("./operations/mixing.jl")




#include("./csv_uploads.jl")

export CapacityError, MixingError, LockedLocationError, AlreadyLocatedInError,OccupancyError #exceptions
export JensenLabUnits # custom units
export Chemical,Solid,Liquid,Gas # chemical types
export Strain # strain type
export Composition,Empty, Mixture, Solution # composition types 
export Contents,Culture, Stock # contents types 
export Location, Labware, Well #location types 
export @labware, @location, @well, @occupancy_cost, @chemical, @strain # macros for constants 

# chemicals 
export molecular_weight, density, pubchemid 
# strains 
export genus, species, strain 
# compositions 
export solids, liquids, chemicals, volume_estimate, quantity
#contents 
export organisms, composition, well, transfer 
# locations 
export location_id , name, is_locked, unlock!,lock!,toggle!
export parent_cost, child_cost, occupancy, occupancy_cost 
export can_move_into, move_into!
#labware
export shape, vendor, catalog, generate_labware, wells
#wells
export capacity 





end # module JLIMS
