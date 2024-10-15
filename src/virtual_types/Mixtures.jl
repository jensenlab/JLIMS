struct Mixture <: Composition
    ingredients::Dict{Ingredient,Unitful.DimensionlessQuantity}
    Mixture(ingredients) = (all(map(x->ustrip(x)>=0,collect(values(ingredients)))) && all(map(x->x.class==:solid,collect(keys(ingredients)))) && sum(collect(values(ingredients)))==100u"percent")  ? new(ingredients) : error("ingredients in a mixture must be solids that have positive %w/w concentrations that sum to 100%")
end 


function Base.show(io::IO,s::Mixture)
    printstyled(io, "Mixture ($(length(collect(keys(s.ingredients)))) ingredient(s))\n";bold=true)
    ings=sort(ingredients(s))
    quants=map(x->s.ingredients[x],ings)
    show(io , DataFrame(Ingredient=ings,Concentration=quants);eltypes=false,summary=false,truncate=0,show_row_number=false,alignment=[:l,:l])
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

function ingredients(mixture::Mixture)
    return collect(keys(mixture.ingredients))
end 



function +(m1::MixtureMass,m2::MixtureMass)

    new_ingredients=Dict{Ingredient,Unitful.DimensionlessQuantity}()
    newmass=m1.quantity+m2.quantity
    m1_ingredients=ingredients(m1.composition)
    m2_ingredients=ingredients(m2.composition) 
    unique_ingredients=unique(vcat(m1_ingredients,m2_ingredients))
    for ingredient in unique_ingredients 
        a1::Unitful.Quantity=0*unit(newmass)
        a2::Unitful.Quantity=0*unit(newmass)
        if ingredient in m1_ingredients
            a1= m1.composition.ingredients[ingredient] * m1.quantity
        end 
        if ingredient in m2_ingredients
            a2= m2.composition.ingredients[ingredient] *m2.quantity
        end 
        new_ingredients[ingredient] =  uconvert(u"percent",(a1+a2)/newmass)
    end 

   return MixtureMass(Mixture(new_ingredients),newmass)

end 

function -(m1::MixtureMass,m2::MixtureMass)

    new_ingredients=Dict{Ingredient,Unitful.DimensionlessQuantity}()
    newmass=m1.quantity-m2.quantity
    m1_ingredients=ingredients(m1.composition)
    m2_ingredients=ingredients(m2.composition) 
    unique_ingredients=unique(vcat(m1_ingredients,m2_ingredients))
    for ingredient in unique_ingredients 
        a1::Unitful.Quantity=0*unit(newmass)
        a2::Unitful.Quantity=0*unit(newmass)
        if ingredient in m1_ingredients
            a1= m1.composition.ingredients[ingredient] * m1.quantity
        end 
        if ingredient in m2_ingredients
            a2= m2.composition.ingredients[ingredient] *m2.quantity
        end 
        new_ingredients[ingredient] =  uconvert(u"percent",(a1-a2)/newmass)
    end 

   return MixtureMass(Mixture(new_ingredients),newmass)

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