__precompile__(true)
module JensenLabUnits

using Unitful 


@dimension 𝐀𝐛 "𝐀b" Absorbance false

@refunit OD "OD" OpticalDesnity 𝐀𝐛 false

@dimension 𝐗 "𝐗"   UndefinedConcentration  false 

@refunit X "X" XConcentration 𝐗 false

@dimension 𝐅𝐥𝐮𝐨𝐫 "Fluor" Fluorescence false 

@refunit RFU "RFU" RelativeFluorescenceUnit 𝐅𝐥𝐮𝐨𝐫 false


@derived_dimension AbsorbanceVolume 𝐀𝐛*Unitful.𝐋^3 true 

const localpromotion=copy(Unitful.promotion)
function __init__()
Unitful.register(JensenLabUnits)
merge!(Unitful.promotion,localpromotion)
end 




end 


# types 
 AbstractConcentration = Union{Unitful.Density,Unitful.Molarity,Unitful.DimensionlessQuantity, JensenLabUnits.Absorbance} # dimensionless quantities represent percentages ex. %v/v or %w/w
 AbstractAmount = Union{Unitful.Amount,Unitful.Mass,Unitful.Volume}  # solid ingredients can be specified by number (moles) or mass, while liquid ingredients are specified by volume 


 function round(q::Unitful.Quantity;kwargs...)
    return round(unit(q),q;kwargs...)
 end 