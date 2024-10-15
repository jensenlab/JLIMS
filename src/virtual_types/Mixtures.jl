struct Mixture <: Composition
    ingredients::Dict{Solid,Unitful.DimensionlessQuantity}
    Mixture(ingredients) = (all(map(x->ustrip(x)>=0,collect(values(ingredients)))) && sum(collect(values(ingredients)))==100u"percent")  ? new(ingredients) : error("ingredients in a mixture must be solids that have positive %w/w concentrations that sum to 100%")
end 



struct MixtureMass <: CompositionQuantity 
    composition::Mixture
    quantity::Unitful.Mass 
end 


function *(mix::Mixture,mass::Unitful.Mass)
    return MixtureMass(mix,mass)
end 

function *(mass::Unitful.Mass,mix::Mixture)
    return MixtureMass(mix,mass)
end 






function mixture_density(m::Mixture)
    ings=m.ingredients
    total_density=0u"g/ml"
    for ing in keys(ings)
        total_density+=ing.density*ings[ing]
    end
    #=
    if typeof(total_density)==Missing
        @warn "One or more of the ingredients have an undefined density"  
    end 
    =#
    return total_density
end 

    

# test mixtures 
#=
x=Mixture(Dict(ingredient["manganese_sulfate"]=>100u"percent"))
y=Mixture(Dict(ingredient["iron_nitrate"]=>100u"percent"))

z=+(*(10u"g",x),*(5u"g",y))

=# 