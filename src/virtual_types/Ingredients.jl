struct Ingredient # predefined individual chemicals or molecules that can be present in a run. We break down any mixed reagents into individual ingredient components.
    id::String 
    name::String # full name 
    molecular_weight::Union{Unitful.Quantity, Missing} # some ingredients have an indeterminate molar mass 
    default_concentration_measure::Unitful.Units 
    Ingredient(id,name,molecular_weight,default_concentration_measure) = typeof(molecular_weight)==Nothing && dimension(default_concentration_measure) == dimension(u"M") ? error("cannot define an indeterminate ingredeint with a default molar concentration, use mass instead ") : new(id,name,molecular_weight,default_concentration_measure)
end 

struct IngredientAmount
    ingredient::Ingredient 
    amount::Unitful.Quantity 
    IngredientAmount(ingredient,amount) = dimension(amount) in map(x->dimension(x),[u"mol",u"g",u"percent"]) && ustrip(amount) >= 0  ? new(ingredient,amount) : error("amounts must have a valid dimension and be nonnegative")
end 






function uconvert_to_default(quantity::Union{Unitful.Quantity,Real},ingredient::Ingredient)

    mass_conc=dimension(1u"g/L")
    mol_conc=dimension(1u"M")
    preferred=ingredient.default_concentration_measure
    new_quantity=deepcopy(quantity)

    if typeof(quantity)==typeof(1.0) && preferred==u"percent"
        new_quantity=uconvert(preferred,quantity)
    end 

    if dimension(quantity)==dimension(preferred)
        new_quantity=uconvert(preferred,quantity)
    elseif dimension(preferred)==mass_conc || dimension(preferred)==mol_conc
        if dimension(preferred)==mass_conc && dimension(quantity)==mol_conc
            new_quantity=uconvert(preferred,quantity*ingredient.molecular_weight)

        elseif dimension(preferred)==mol_conc && dimension(quantity)==mass_conc
            new_quantity=uconvert(preferred,quantity/ingredient.molecular_weight)
        end 

    else
        error( ArgumentError("supplied quantity has dimensions $(dimension(quantity)) which are incompatible with $(ingredient.name)'s preferred concentration dimensions ($(dimension(ingredient.default_concentration_measure)))."))

    end 
    return new_quantity
end 





# Test ingredients 
#=
ingredient=Dict{String,Ingredient}()


ingredient["water"]=Ingredient(
    "water",
    "Water",
    18.01u"g/mol",
    u"percent" # liquid reagent
)

ingredient["iron_nitrate"]=Ingredient(
    "iron_nitrate",
    "Iron (III) Nitroate nonohydrate",
    404.0u"g/mol",
    u"g/L"
)

ingredient["iron_sulfate"]=Ingredient(
    "iron_sulfate",
    "Iron (II) Sulfate heptahydrate",
    278.01u"g/mol",
    u"g/L"
)

ingredient["magnesium_sulfate"]=Ingredient(
    "magnesium_sulfate",
    "Magnesium Sulfate Heptahydrate",
    246.47u"g/mol",
    u"g/L"
)

ingredient["manganese_sulfate"]=Ingredient(
    "manganese_sulfate",
    "Manganese Sulfate Monohydrate",
    169.02u"g/mol",
    u"g/L"
)
=# 




