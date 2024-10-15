
 

struct Culture  <: Composition 
    ingredients::Dict{Ingredient,AbstractConcentration}
    function Culture(ingredients)  
        # test for issues 
        (all(map(x->ustrip(x)>=0,collect(values(ingredients))))) || error("cultures must use concentrations that are nonnegative")
        liquids=filter(x->x isa Liquid,collect(keys(ingredients)))
        length(liquids) >= 1 || error("cultures must contain at least one liquid solvent")
        lqvals=map(x->ingredients[x],liquids)
        all(isa.(lqvals,(Unitful.DimensionlessQuantity,))) || error("liquid ingredients must have a %v/v concentration in the culture")
        round(sum(lqvals),digits=8) ==100u"percent" || error("liquid ingredient concentrations must sum to 100 %v/v")
        solids=filter(x-> x isa Solid,collect(keys(ingredients)))
        for s in solids 
            if isa(ingredients[s],Unitful.Density) 
                continue 
            elseif isa(ingredients[s],Unitful.Molarity)
                ingredients[s]=convert(u"g/L",ingredients[s],s)
            else 
                error("$(s.name)'s concentration must be given either by a Density or Molarity")
            end 
        end 
        organisms=filter(x-> x isa Organism,collect(keys(ingredients)))
        length(organisms) >= 1 || error("there must be at least one organism in a culture")
        orgvals=map(x->ingredients[x],organisms)
        all(isa.(orgvals,(JensenLabUnits.Absorbance))) || error("all organisms must have an absorbance concentration")
        return new(ingredients)
    end 
end 





struct CultureVolume <: CompositionQuantity
    composition::Culture 
    quantity::Unitful.Volume 
    CultureVolume(composition,quantity) =  ustrip(quantity) >= 0  ? new(composition,quantity) : error("volumes must be nonnegative")
end 


function *(cul::Culture,vol::Unitful.Volume)
    return CultureVolume(cul,vol)
end 

function *(vol::Unitful.Volume,cul::Culture)
    return CultureVolume(cul,vol)
end 

