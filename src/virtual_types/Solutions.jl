# Solutions are liquid combinations that can have solids dissolved in them. We specify the concentration of liquids as %v/v 

struct Solution  <: Composition 
    ingredients::Dict{Ingredient,AbstractConcentration}
    function Solution(ingredients)  
        # test for issues 
        (all(map(x->ustrip(x)>=0,collect(values(ingredients))))) || error("solutions must use concentrations that are nonnegative")
        length(filter(x->x.class==:liquid,collect(keys(ingredients)))) > 0 || error("solutions must contain at least one liquid solvent")
        lqvals=map(x->ingredients[x],filter(x->x.class==:liquid,collect(keys(ingredients))))
        all(isa.(lqvals,(Unitful.DimensionlessQuantity,))) || error("liquid ingredients must have a %v/v concentration in the solution")
        round(sum(lqvals),digits=8) ==100u"percent" || error("liquid ingredient concentrations must sum to 100 %v/v")
        solids=filter(x->x.class==:solid,keys(ingredients))
        for solid_ingredient in solids 
            if isa(ingredients[solid_ingredient],Unitful.Density) 
                continue 
            elseif isa(ingredients[solid_ingredient],Unitful.Molarity)
                continue
            else 
                error("$(solid_ingredient.name)'s concentration must be given either by a Density or Molarity")
            end 
        end 
        organismvals=map(x->ingredients[x],filter(x->x.class==:organism,collect(keys(ingredients))))
        all(isa.(organismvals,(JensenLabUnits.Absorbance))) || error("organsims must have a concentration based on a culture absorance value, such as OD")
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


function ingredients(solution::Solution)
    return collect(keys(solution.ingredients))
end 


function +(s1::SolutionVolume,s2::SolutionVolume;prefconc=Dict(:liquid=>u"percent",:solid=>u"g/l",:organism=>u"OD")) 

    new_ingredients=Dict{Ingredient,AbstractConcentration}()
    newvolume=s1.quantity+s2.quantity
    s1_ingredients=ingredients(s1.composition)
    s2_ingredients=ingredients(s2.composition) 
    unique_ingredients=unique(vcat(s1_ingredients,s2_ingredients))
    for ingredient in unique_ingredients 
        a1::Unitful.Quantity=0*prefconc[ingredient.class] *unit(newvolume)
        a2::Unitful.Quantity=0*prefconc[ingredient.class] *unit(newvolume)
        if ingredient in s1_ingredients
            a1= s1.composition.ingredients[ingredient] *s1.quantity 
        end 
        if ingredient in s2_ingredients
             a2=s2.composition.ingredients[ingredient] *s2.quantity 
        end 

            new_ingredients[ingredient] = uconvert(prefconc[ingredient.class],((a1+a2) / newvolume ))

    end 
     
    return *(Solution(new_ingredients),newvolume)
end 

function +(s1::SolutionVolume,m1::MixtureMass;prefconc=Dict(:liquid=>u"percent",:solid=>u"g/l",:organism=>u"OD"))
    new_ingredients=Dict{Ingredient,AbstractConcentration}()
    newvolume=deepcopy(s1.quantity)
    s1_ingredients=ingredients(s1.composition)
    m1_ingredients=ingredients(m1.composition)
    unique_ingredients=unique(vcat(s1_ingredients,m1_ingredients))
    for ingredient in unique_ingredients
        a1::Unitful.Quantity=0*prefconc[ingredient.class] *unit(newvolume)
        a2::Unitful.Quantity=0*prefconc[ingredient.class] *unit(newvolume)
        if ingredient in s1_ingredients
            a1=s1.composition.ingredients[ingredient]*s1.quantity
        end 
        if ingredient in m1_ingredients
            a2=m1.composition.ingredients[ingredient]*m1.quantity
        end 
        new_ingredients[ingredient]=uconvert(prefconc[ingredient.class],((a1+a2)/newvolume))
    end 
    return *(Solution(new_ingredients),newvolume)
end 


function +(s1::SolutionVolume)
    return s1
end 


    
function -(s1::SolutionVolume,s2::SolutionVolume;prefconc=Dict(:liquid=>u"percent",:solid=>u"g/l",:organism=>u"OD")) 

    new_ingredients=Dict{Ingredient,AbstractConcentration}()
    newvolume=s1.quantity-s2.quantity
    s1_ingredients=ingredients(s1.composition)
    s2_ingredients=ingredients(s2.composition) 
    unique_ingredients=unique(vcat(s1_ingredients,s2_ingredients))
    for ingredient in unique_ingredients 
        a1::Unitful.Quantity=0*prefconc[ingredient.class] *unit(newvolume)
        a2::Unitful.Quantity=0*prefconc[ingredient.class] *unit(newvolume)
        if ingredient in s1_ingredients
            a1= s1.composition.ingredients[ingredient] *s1.quantity 
        end 
        if ingredient in s2_ingredients
             a2=s2.composition.ingredients[ingredient] *s2.quantity 
        end 

            new_ingredients[ingredient] = uconvert(prefconc[ingredient.class],((a1-a2) / newvolume ))

    end 
     
    return *(Solution(new_ingredients),newvolume)
end 

function -(s1::SolutionVolume,m1::MixtureMass;prefconc=Dict(:liquid=>u"percent",:solid=>u"g/l",:organism=>u"OD"))
    new_ingredients=Dict{Ingredient,AbstractConcentration}()
    newvolume=deepcopy(s1.quantity)
    s1_ingredients=ingredients(s1.composition)
    m1_ingredients=ingredients(m1.composition)
    unique_ingredients=unique(vcat(s1_ingredients,m1_ingredients))
    for ingredient in unique_ingredients
        a1::Unitful.Quantity=0*prefconc[ingredient.class] *unit(newvolume)
        a2::Unitful.Quantity=0*prefconc[ingredient.class] *unit(newvolume)
        if ingredient in s1_ingredients
            a1=s1.composition.ingredients[ingredient]*s1.quantity
        end 
        if ingredient in m1_ingredients
            a2=m1.composition.ingredients[ingredient]*m1.quantity
        end 
        new_ingredients[ingredient]=uconvert(prefconc[ingredient.class],((a1-a2)/newvolume))
    end 
    return *(Solution(new_ingredients),newvolume)
end 

function +(m1::MixtureMass,s1::SolutionVolume;kwargs...)
    return +(s1,m1;kwargs...)
end 


function -(s1::SolutionVolume)
    return s1
end 

#=
solution=Dict{String,Solution}()


solution["water"]=Solution(
    "water",
    Dict(
        ingredient["water"] => 100u"percent"
    )
)

solution["iron_nitrate_100x"]=Solution(
    "iron_nitrate_100x",
    Dict(
        ingredient["iron_nitrate"]=> 0.1u"mg/ml",
        ingredient["water"]=> 100u"percent"
    )
)

solution["iron_sulfate_100x"]=Solution(
    "iron_sulfate_100x",
    Dict(
        ingredient["iron_sulfate"]=> 0.2u"mg/ml",
        ingredient["water"]=>100u"percent"
    )
)



test=Solution("test", 
Dict(
    ingredient["water"]=>100u"percent",
    ingredient["iron_nitrate"]=>20u"mM",
    ingredient["SMU_UA159"]=>0.4u"OD"
))

test2=Solution("test2",
Dict(
    ingredient["water"]=>100u"percent",
    ingredient["manganese_sulfate"]=>0.2u"g/l"
))
=#