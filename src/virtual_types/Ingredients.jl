









struct Ingredient # predefined individual chemicals  that can be present in a run. We break down any mixed reagents into individual ingredient components.
    name::String # full name 
    molecular_weight::Union{Unitful.MolarMass, Missing} # some ingredients have an indeterminate molar mass 
    density::Union{Unitful.Density,Missing}
    class::Symbol
    Ingredient(name,molecular_weight,density,class) = class ∈ [:solid,:liquid,:organism] ? new(name,molecular_weight,density,class) : error("declared class must be either :solid , :liquid ,or :organism ") 
end 

function Base.show(io::IO,ing::Ingredient)
    print(io, ing.name)
end 

function Base.show(io::IO, ::MIME"text/plain", ing::Ingredient)
    println(io, ing.name) 

    if !ismissing(ing.molecular_weight)
        println(io ,"molecular weight: ",ing.molecular_weight)
    end 
    if !ismissing(ing.density)
        println(io,"density: ", ing.density)
    end 
    println(io,"class: ",string(ing.class))
end 


function Base.sort(v::Vector{T}) where T<: Ingredient
    idxs=sortperm(map(x->x.name,v))
    return v[idxs]
end 


function convert(y::Unitful.DensityUnits,x::Unitful.Molarity,ingredient::Ingredient)
    typeof(ingredient.molecular_weight)==Missing ? error(" $(ingredient.name)'s molecular weight is unknown") : return uconvert(y,x *ingredient.molecular_weight)
end 

function convert(y::Unitful.MolarityUnits,x::Unitful.Density,ingredient::Ingredient)
    typeof(ingredient.molecular_weight)==Missing ? error(" $(ingredient.name)'s molecular weight is unknown") : return uconvert(y,x / ingredient.molecular_weight)
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


water=Ingredient(
    "water",
    18.01u"g/mol" ,
    1u"g/L",
    :liquid
)

iron_nitrate=Ingredient(
    "iron_nitrate",
    404.0u"g/mol",
    missing,
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


