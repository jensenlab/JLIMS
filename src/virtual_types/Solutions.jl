struct Solution 
    id::String 
    ingredients::Dict{Ingredient,Unitful.Quantity}
    Solution(id,ingredients) = (all(map(x->ustrip(x)>=0,collect(values(ingredients)))) && all(map(x->dimension(x) in map(x->dimension(x),[u"percent",u"M",u"g/l"]),collect(values(ingredients)))))  ? new(id,ingredients) : error("solutions must use concentrations that are nonnegative")
end 
Solution(ingredients)= Solution(id(),ingredients)





struct SolutionVolume
    solution::Solution 
    volume::Unitful.Quantity 
    SolutionVolume(solution,volume) = dimension(volume) ==dimension(u"L") && ustrip(volume) >= 0  ? new(solution,volume) : error("volumes must be valid and nonnegative")
end 
import Base: + , - , * 


function *(sol::Solution,vol::Unitful.Quantity)
    return SolutionVolume(sol,vol)
end 

function *(vol::Unitful.Quantity,sol::Solution)
    return SolutionVolume(sol,vol)
end 


function ingredients(solution::Solution)
    return collect(keys(solution.ingredients))
end 


function +(s1::SolutionVolume,s2::Union{IngredientAmount,SolutionVolume}) 
    newvolume=deepcopy(s1.volume)
    new_ingredients=Dict{Ingredient,Unitful.Quantity}()
    if typeof(s2)==IngredientAmount
        new_ingredients=Dict{Ingredient,Unitful.Quantity}()
        s1_ingredients=ingredients(s1.solution)
        s2_ingredients=s2.ingredient
        unique_ingredients=unique(vcat(s1_ingredients,s2_ingredients))
        for ingredient in unique_ingredients 
            defconc=ingredient.default_concentration_measure
            defamt=defconc*unit(newvolume)
            a1::Unitful.Quantity=0*defamt
            a2::Unitful.Quantity=0*defamt
            if ingredient in s1_ingredients
                a1= uconvert_to_default(s1.solution.ingredients[ingredient],ingredient) *s1.volume 
            end 
            if ingredient == s2_ingredients
                a2=s2.amount 
            end 
            new_ingredients[ingredient] = (a1+a2) / newvolume
        end 
    else 
        newvolume=s1.volume+s2.volume
        s1_ingredients=ingredients(s1.solution)
        s2_ingredients=ingredients(s2.solution) 
        unique_ingredients=unique(vcat(s1_ingredients,s2_ingredients))
        for ingredient in unique_ingredients 
            defconc=ingredient.default_concentration_measure
            defamt=defconc*unit(new_volume)
            a1::Unitful.Quantity=0*defamt
            a2::Unitful.Quantity=0*defamt
            if ingredient in s1_ingredients
                a1= uconvert_to_default(s1.solution.ingredients[ingredient],ingredient) *s1.volume 
            end 
            if ingredient in s2_ingredients
                a2=uconvert_to_default(s2.solution.ingredients[ingredient],ingredient) *s2.volume 
            end 
            new_ingredients[ingredient] = (a1+a2) / newvolume 
        
        end 
    end 
    return *(Solution(new_ingredients),newvolume)
end 


function +(s1::SolutionVolume)
    return s1
end 


function +(s1::SolutionVolume,s2::Union{IngredientAmount,SolutionVolume},x...)
        a=+(s1,s2)
    return +(a,x...)
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
=#




