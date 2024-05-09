









struct Ingredient # predefined individual chemicals  that can be present in a run. We break down any mixed reagents into individual ingredient components.
    name::String # full name 
    molecular_weight::Union{Unitful.MolarMass, Missing} # some ingredients have an indeterminate molar mass 
    class::Symbol
    Ingredient(name,molecular_weight,class) = class ∈ [:solid,:liquid,:organism] ? new(name,molecular_weight,class) : error("declared class must be either :solid , :liquid ,or :organism ") 
end 


function convert(::Type{Unitful.Density},x::Unitful.Molarity,ingredient::Ingredient)
    return uconvert(u"g/L",x *ingredient.molecular_weight)
end 

function convert(::Type{Unitful.Molarity},x::Unitful.Density,ingredient::Ingredient)
    return uconvert(u"M",x / ingredient.molecular_weight)
end 



#=
function uconvert_to_default(quantity::Union{Unitful.Quantity,Real},ingredient::Ingredient)

    mass_conc=dimension(1u"g/L")
    mol_conc=dimension(1u"M")
    preferred=ingredient.default_concentration_measure
    new_quantity=deepcopy(quantity)

    if typeof(quantity)==Real && preferred==u"percent"
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
=#




# Test ingredients 
#=
ingredient=Dict{String,Ingredient}()


ingredient["water"]=Ingredient(
    "water",
    18.01u"g/mol" ,
    :liquid
)

ingredient["iron_nitrate"]=Ingredient(
    "iron_nitrate",
    404.0u"g/mol",
    :solid
)

ingredient["iron_sulfate"]=Ingredient(
    "iron_sulfate",
    278.01u"g/mol",
    :solid
)

ingredient["magnesium_sulfate"]=Ingredient(
    "magnesium_sulfate",
    246.47u"g/mol",
    :solid
)

ingredient["manganese_sulfate"]=Ingredient(
    "manganese_sulfate",
    169.02u"g/mol",
    :solid
)

ingredient["SMU_UA159"]=Ingredient(
    "SMU_UA159",
    missing,
    :organism
)
=#


