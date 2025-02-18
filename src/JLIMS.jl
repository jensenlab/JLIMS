module JLIMS

using 
    Unitful, # unit tracking and conversion
    UnitfulParsableString, # parse string unit symbols as Unitful units
    SQLite, # database framework CHESS uses. 
    DBInterface, # standard interface for database connections
    DataFrames, # for SQL returns 
    AbstractTrees, # used for computing and storing movements
    HTTP, # chemical parsing only
    JSON, # chemical parsing only 
    UUIDs, # used for generating default labware names
    Dates #used for converting time objects. 
import Base: +,-,*,/,convert, show ,sort , promote_rule,round , in, ==,empty,empty!, hash, isapprox # all overloaded by this package
import AbstractTrees: children,parent,nodevalue

include("./Units/JensenLabUnits.jl")

    using .JensenLabUnits
    Unitful.register(JensenLabUnits)

Unitful.promote_unit(::S,::T) where {S<:Unitful.VolumeUnits,T<:Unitful.VolumeUnits} = u"mL"
Unitful.promote_unit(::S,::T) where {S<:Unitful.MassUnits,T<:Unitful.MassUnits} = u"g" 
include("./exceptions.jl")
include("./environments/Attributes.jl")

include("./locations/Location.jl")
include("./locations/LocationRef.jl")
include("./locations/Labware.jl")
include("./stocks/Chemicals.jl")
include("./stocks/Strains.jl")
include("./stocks/Stocks.jl")
include("./locations/Well.jl")
include("./stocks/chemical_parsing.jl")
include("./barcodes/barcodes.jl")


include("./operations/movement.jl")
include("./operations/mixing.jl")
# basic database functions
include("./database/database.jl")
include("./database/db_utils.jl")
include("./database/ledger.jl")
include("./database/caching.jl")
include("./database/uploads.jl")
include("./database/generate_location.jl")
include("./database/encumbrances.jl")
# reconstruction
include("./database/reconstruction/reconstruction_utils.jl")
include("./database/reconstruction/reconstruct_contents.jl")
include("./database/reconstruction/reconstruct_parent.jl")
include("./database/reconstruction/reconstruct_children.jl")
include("./database/reconstruction/reconstruct_attributes.jl")
include("./database/reconstruction/reconstruct_environment.jl")
include("./database/reconstruction/reconstruct_lock.jl")
include("./database/reconstruction/reconstruct_activity.jl")
include("./database/reconstruction/reconstruct_location.jl")
# cache repair 
include("./database/validation_and_repair/repair_content_caches.jl")
include("./database/validation_and_repair/repair_movement_caches.jl")
include("./database/validation_and_repair/repair_environment_attribute_caches.jl")
include("./database/validation_and_repair/repair_activity_caches.jl")
include("./database/validation_and_repair/repair_lock_caches.jl")
include("./database/validation_and_repair/cache_repair.jl")
include("./database/validation_and_repair/validation.jl")

# ledger updates 
include("./database/update_operation.jl")

export WellCapacityError, MixingError, LockedLocationError, AlreadyLocatedInError,OccupancyError #exceptions
export JensenLabUnits # custom units
export Attribute, AttributeDict,set_attribute!,set_attribute ,value
export Chemical,Solid,Liquid,Gas # chemical types
export Strain # strain type
export Stock,Empty, Mixture, Solution, Culture # Stock types 
export Location, Labware, Well #location types 
export LocationRef
export @labware, @location, @well, @occupancy_cost, @chemical, @strain , @attribute # macros for constants 
export get_mw_density
# chemicals 
export molecular_weight, density, pubchemid 
# strains 
export genus, species, strain 
# Stocks 
export solids, liquids, chemicals, organisms, volume_estimate, quantity, component_display
# locations 
export location_id, name, is_locked, unlock!,lock!,toggle_lock!, unlock, lock, toggle_lock, ancestors, environment,attributes , is_active, activate!,activate, deactivate!,deactivate, toggle_activity!,toggle_activity
export parent_cost, child_cost, occupancy, occupancy_cost , parent, children 
export can_move_into, move_into!,move_into
#labware
export shape, vendor, catalog, wells
#wells
export capacity, stock, cost,  sterilize!,sterilize,transfer!,transfer, drain!,drain,deposit!,deposit,withdraw!,withdraw
#database
export create_db
#ledger.jl
export append_ledger,insert_ledger,update_ledger
#db_utils 
export @connect_SQLite, execute_db, query_db,sql_transaction,sql_commit,sql_rollback,julia_time,db_time
#uploads 
export @upload ,@update, upload_tag, upload_barcode, update_barcode , process_update
#queries
export get_last_ledger_id,get_last_sequence_id,get_last_encumbrance_id,get_last_protocol_id,get_sequence_id
#generate_location
export generate_location
#caching and fetching 
export cache , fetch_cache, get_location_info
#reconstruct_location.jl
export reconstruct_location,reconstruct_location!
#reconstruct_contents.jl
export reconstruct_contents, reconstruct_contents!
#reconstruct_parent.jl
export reconstruct_parent , reconstruct_parent!
#reconstruct_children.jl
export reconstruct_children,reconstruct_children!
#reconstruct_attributes.jl
export reconstruct_attributes,reconstruct_attributes!
#reconstruct_environment 
export reconstruct_environment,reconstruct_environment!
#reconstruct_lock.jl
export reconstruct_lock,reconstruct_lock!
#reconstruct_activity.jl
export reconstruct_activity,reconstruct_activity!
#barcodes
export Barcode, assign_barcode!,assign_barcode
export @protocol ,upload_protocol,upload_experiment, @encumber, upload_encumbrance,encumber_cache
end # module JLIMS
