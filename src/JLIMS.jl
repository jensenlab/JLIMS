module JLIMS
import Base: +,-,*,convert
using 
    Unitful,
    UnitfulParsableString,
    CSV,
    DataFrames


include("./Units/JensenLabUnits.jl")

    using .JensenLabUnits
    Unitful.register(JensenLabUnits)
#basic information 

#virtual types 
include("./virtual_types/Ingredients.jl")
include("./virtual_types/Compositions.jl")
include("./virtual_types/Mixtures.jl")
include("./virtual_types/Solutions.jl")
include("./virtual_types/Empty.jl")
include("./virtual_types/Containers.jl")

#physical types
include("./physical_types/Well.jl")
include("./physical_types/Stocks.jl")


include("./csv_uploads.jl")


function Composition(ingredients)
    if all(map(x->x.class==:solid,collect(keys(ingredients))))
        return Mixture(ingredients)
    else
        return Solution(ingredients)
    end 
end 


export  JensenLabUnits
export Ingredient, convert
export Composition, CompositionQuantity
export Mixture, MixtureMass, *, ingredients, +,-
export Soluiton, SolutionVolume
export Empty , EmptyQuantity
export Container
export Stock, LiquidStock,SolidStock,deposit,withdraw,transfer
export Well
export parse_ingredient_csv,parse_composition_csv,parse_container_csv



end # module JLIMS
