module JLIMS
import Base: +,-,*,convert
using 
    Unitful,
    UUIDs,
    Dates,
    CSV,
    DataFrames


include("./Units/JensenLabUnits.jl")

    using .JensenLabUnits
    Unitful.register(JensenLabUnits)
#basic information 
include("./IDs/IDs.jl")
include("./Locations/Locations.jl")

#virtual types 
include("./virtual_types/Ingredients.jl")
include("./virtual_types/Compositions.jl")
include("./virtual_types/Mixtures.jl")
include("./virtual_types/Solutions.jl")
include("./virtual_types/Containers.jl")

#physical types
include("./physical_types/Labware.jl")
include("./physical_types/Stocks.jl")

include("./virtual_types/Dispenses.jl")
include("./virtual_types/Runs.jl")
include("./virtual_types/Environments.jl")
include("./virtual_types/Experiments.jl")

include("./csv_uploads.jl")


function Composition(name,ingredients)
    if all(map(x->x.class==:solid,collect(keys(ingredients))))
        return Mixture(name,ingredients)
    else
        return Solution(name,ingredients)
    end 
end 


export  JensenLabUnits
export id, named_id
export Location
export Ingredient, convert
export Composition, CompositionQuantity
export Mixture, MixtureMass, *, ingredients, +,-
export Soluiton, SolutionVolume
export Container
export Dispense
export Environment
export Run 
export Experiment
export Labware
export Stock, LiquidStock,SolidStock,deposit,withdraw,transfer
export parse_ingredient_csv,parse_composition_csv,parse_container_csv



end # module JLIMS
