module JLIMS
import Base: +,-,*,/,convert, show ,sort , promote_rule,round,convert , in 
using 
    Unitful,
    UnitfulParsableString,
    CSV,
    DataFrames,
    AbstractTrees,
    HTTP,
    JSON


include("./Units/JensenLabUnits.jl")

    using .JensenLabUnits
    Unitful.register(JensenLabUnits)

Unitful.promote_unit(::S,::T) where {S<:Unitful.VolumeUnits,T<:Unitful.VolumeUnits} = u"mL"
#basic information 

#virtual types 

#include("./virtual_types/Ingredients.jl")
#include("./virtual_types/Compositions.jl")
#include("./virtual_types/Mixtures.jl")
#include("./virtual_types/Solutions.jl")
#include("./virtual_types/Empty.jl")
include("./locations/Location.jl")
include("./locations/Labware.jl")
include("./locations/Well.jl")
include("./contents/Chemicals.jl")
include("./exceptions.jl")
include("./contents/Strains.jl")
include("./contents/Compositions.jl")
include("./contents/chemical_parsing.jl")
include("./contents/Contents.jl")
include("./operations/movement.jl")
include("./operations/mixing.jl")

#physical types
#include("./physical_types/Stocks.jl")
#nclude("./physical_types/Cultures.jl")


#include("./csv_uploads.jl")

export CapacityError, MixingError,SummationError, LockedLocationError, AlreadyLocatedInError,OccupancyError
export  JensenLabUnits
export Ingredient,Chemical,Solid,Liquid,Strain, convert,Gas
export Composition
export Mixture
export Solution
export Culture
export Empty
export Location, id, parent,children, is_locked,name, unlock!,lock!,toggle!
export occupancy_cost,parent_cost, child_cost,occupancy
export can_move_into,move_into! 
export Labware, Plate, Bottle, Dish, Reservior, Tube,shape,vendor,catalog, generate,wells
export Well, capacity
export @labware, @location, @well, @occupancy_cost, @chemical, @strain
export get_mw_density,molecular_weight,density,pubchemid
export ChemicalConcentration, SolidConcentration, prefconcunits,prefquantunits
export quantity,solids,liquids,chemicals,volume_estimate
export +,-
export Stock,deposit,withdraw,transfer,well,quantity,composition
export Culture, promote_rule, in 
#export parse_chemical_csv,parse_composition_csv,parse_container_csv,parse_strain_csv



end # module JLIMS
