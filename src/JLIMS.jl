module JLIMS

using 
    Unitful,
    UnitfulParsableString,
    #CSV,
    DataFrames,
    AbstractTrees,
    HTTP, # chemical parsing only
    JSON, # chemical parsing only 
    UUIDs # used for generating labware name
import Base: +,-,*,/,convert, show ,sort , promote_rule,round , in, ==,empty,empty!, hash # all overloaded by this package
import AbstractTrees: children,parent,nodevalue

include("./Units/JensenLabUnits.jl")

    using .JensenLabUnits
    Unitful.register(JensenLabUnits)

Unitful.promote_unit(::S,::T) where {S<:Unitful.VolumeUnits,T<:Unitful.VolumeUnits} = u"mL"
Unitful.promote_unit(::S,::T) where {S<:Unitful.MassUnits,T<:Unitful.MassUnits} = u"g" 
include("./exceptions.jl")
include("./environments/Attributes.jl")
include("./locations/Location.jl")
include("./locations/Labware.jl")
include("./stocks/Chemicals.jl")
include("./stocks/Strains.jl")
include("./stocks/Stocks.jl")
include("./locations/Well.jl")
include("./stocks/chemical_parsing.jl")

include("./operations/movement.jl")
include("./operations/mixing.jl")
include("./database/database.jl")
include("./database/db_utils.jl")
include("./database/caching.jl")
include("./database/fetching.jl")
include("./database/uploads.jl")




#include("./csv_uploads.jl")

export WellCapacityError, MixingError, LockedLocationError, AlreadyLocatedInError,OccupancyError #exceptions
export JensenLabUnits # custom units
export Attribute, AttributeDict,set_attribute!,set_attribute ,value
export Chemical,Solid,Liquid,Gas # chemical types
export Strain # strain type
export Stock,Empty, Mixture, Solution, Culture # Stock types 
export Location, Labware, Well #location types 
export @labware, @location, @well, @occupancy_cost, @chemical, @strain , @attribute # macros for constants 
export get_mw_density
# chemicals 
export molecular_weight, density, pubchemid 
# strains 
export genus, species, strain 
# Stocks 
export solids, liquids, chemicals, organisms, volume_estimate, quantity
# locations 
export location_id, name, is_locked, unlock!,lock!,toggle_lock!, unlock, lock, toggle_lock, ancestors, environment,attributes , is_active, activate!,activate, deactivate!,deactivate, toggle_activity!,toggle_activity
export parent_cost, child_cost, occupancy, occupancy_cost 
export can_move_into, move_into!
#labware
export shape, vendor, catalog, generate_labware, wells
#wells
export capacity, stock, sterilize!,sterilize,transfer!,transfer, drain!,drain
#database
export create_db
#db_utils 
export connect_SQLite
#uploads 
export @upload 



end # module JLIMS
