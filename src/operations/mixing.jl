Base.promote_rule(::Type{Mixture},::Type{Solution}) = Solution


# Mixture < Solution in terms of restrictions

function +(c1::CompositionQuantity,c2::CompositionQuantity;prefconc=Dict(Liquid=>u"percent",Solid=>u"g/l"))
    # compute the resulting type and quantity 
    ResultType=promote_type(typeof(c1.composition),typeof(c2.composition))
    result_type=Unitful.Volume
    result_quantity=0u"mL"
    if ResultType == Mixture
        result_type=Unitful.Mass
        result_quantity=0u"g"
    end 

    if c1.quantity isa result_type
        result_quantity+=c1.quantity
    end
    if c2.quantity isa result_type
        result_quantity+=c2.quantity
    end 
    new_ingredients=Dict{Ingredient,AbstractConcentration}()
    c1_ingredients=ingredients(c1.composition)
    c2_ingredients=ingredients(c2.composition)
    unique_ingredients=unique(vcat(c1_ingredients,c2_ingredients))
    for ingredient in unique_ingredients
        a1::Unitful.Quantity=0*prefconc[typeof(ingredient)] *unit(result_quantity)
        a2::Unitful.Quantity=0*prefconc[typeof(ingredient)] *unit(result_quantity)
        if ingredient in c1_ingredients
            a1=c1.composition.ingredients[ingredient]*c1.quantity
        end 
        if ingredient in c2_ingredients
            a2=c2.composition.ingredients[ingredient]*c2.quantity
        end 
        new_ingredients[ingredient]=uconvert(prefconc[typeof(ingredient)],((a1+a2)/result_quantity))
    end 
    return *(ResultType(new_ingredients),result_quantity)
end 


function +(s1::CompositionQuantity)
    return s1
end 


function -(c1::CompositionQuantity,c2::CompositionQuantity;prefconc=Dict(Liquid=>u"percent",Solid=>u"g/l"))
    # compute the resulting type and quantity 
    ResultType=promote_type(typeof(c1.composition),typeof(c2.composition))
    quanttype=Unitful.Volume
    if ResultType == Mixture
        quanttype=Unitful.Mass
    end 
    empty_quants=[Unitful.Volume => 0u"mL",Unitful.Mass=>0u"g"]
    c1_type=typeof(c1.quantity)
    c2_type=typeof(c2.quantity)
    result_quantity= empty_quants[quanttype]
    if c1_type == quanttype
        result_quantity+=c1.quantity
    end
    if c2_type == quanttype 
        result_quantity-=c2.quantity
    end 
    new_ingredients=Dict{T,C}() where {T<:Ingredient,C<:AbstractConcentration}
    c1_ingredients=ingredients(c1.composition)
    c2_ingredients=ingredients(c2.composition)
    unique_ingredients=unique(vcat(c1_ingredients,c2_ingredients))
    for ingredient in unique_ingredients
        a1::Unitful.Quantity=0*prefconc[typeof(ingredient)] *unit(result_quantity)
        a2::Unitful.Quantity=0*prefconc[typeof(ingredient)] *unit(result_quantity)
        if ingredient in c1_ingredients
            a1=c1.composition.ingredients[ingredient]*c1.quantity
        end 
        if ingredient in c2_ingredients
            a2=c2.composition.ingredients[ingredient]*c2.quantity
        end 
        new_ingredients[ingredient]=uconvert(prefconc[typeof(ingredient)],((a1-a2)/result_quantity))
    end 
    return *(ResultType(new_ingredients),result_quantity)
end 


function -(c1::CompositionQuantity)
    return s1
end 