module JLIMS
import Base: +,-,*,convert, show ,sort , promote_rule,round,convert 
using 
    Unitful,
    UnitfulParsableString,
    CSV,
    DataFrames


include("./Units/JensenLabUnits.jl")

    using .JensenLabUnits
    Unitful.register(JensenLabUnits)

Unitful.promote_unit(::S,::T) where {S<:Unitful.VolumeUnits,T<:Unitful.VolumeUnits} = u"mL"
#basic information 

#virtual types 
include("./exceptions.jl")
include("./virtual_types/Ingredients.jl")
include("./virtual_types/Compositions.jl")
include("./virtual_types/Mixtures.jl")
include("./virtual_types/Solutions.jl")
include("./virtual_types/Empty.jl")
include("./virtual_types/Containers.jl")
include("./operations/mixing.jl")
#physical types
include("./physical_types/Well.jl")
include("./physical_types/Stocks.jl")
include("./physical_types/Cultures.jl")


include("./csv_uploads.jl")



export CapacityError
export  JensenLabUnits
export Ingredient,Chemical,Organism,Solid,Liquid,Strain, convert
export Composition, CompositionQuantity, ingredients
export Mixture, MixtureMass,*
export Solution, SolutionVolume
export Culture, CultureVolume
export Empty , EmptyQuantity
export Container
export +,-
export Stock, LiquidStock,SolidStock,EmptyStock,deposit,withdraw,transfer,well
export Culture, promote_rule
export Well
export parse_chemical_csv,parse_composition_csv,parse_container_csv,parse_strain_csv



end # module JLIMS
