# Solutions are liquid combinations that can have solids dissolved in them. We specify the concentration of liquids as %v/v 

struct Solution  <: Composition 
    ingredients::Dict{Chemical,AbstractConcentration}
    function Solution(ingredients)  
        # test for issues 
        (all(map(x->ustrip(x)>=0,collect(values(ingredients))))) || error("solutions must use concentrations that are nonnegative")
        liquids=filter(x->x isa Liquid,collect(keys(ingredients)))
        length(liquids) >= 1 || error("solutions must contain at least one liquid solvent")
        lqvals=map(x->ingredients[x],liquids)
        all(isa.(lqvals,(Unitful.DimensionlessQuantity,))) || error("liquid ingredients must have a %v/v concentration in the solution")
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
        return new(ingredients)
    end 
end 







struct SolutionVolume <: CompositionQuantity
    composition::Solution 
    quantity::Unitful.Volume 
    SolutionVolume(composition,quantity) =  ustrip(quantity) >= 0  ? new(composition,quantity) : error("volumes must be nonnegative")
end 


function *(sol::Solution,vol::Unitful.Volume)
    return SolutionVolume(sol,vol)
end 

function *(vol::Unitful.Volume,sol::Solution)
    return SolutionVolume(sol,vol)
end 





