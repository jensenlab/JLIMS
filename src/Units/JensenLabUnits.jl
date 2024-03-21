module JensenLabUnits

using Unitful 


@dimension 𝐀𝐛 "𝐀b" Absorbance false

@refunit OD "OD" OpticalDesnity 𝐀𝐛 false

@dimension 𝐗 "𝐗"   UndefinedConcentration  false 

@refunit X "X" XConcentration 𝐗 false

@dimension 𝐅𝐥𝐮𝐨𝐫 "Fluor" Fluorescence false 

@refunit RFU "RFU" RelativeFluorescenceUnit 𝐅𝐥𝐮𝐨𝐫 false



Unitful.register(JensenLabUnits)


end 
