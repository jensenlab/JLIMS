
abstract type Composition end 

abstract type CompositionQuantity end 




function Composition(ingredients)
    solids=filter(x-> x isa Solid,collect(keys(ingredients)))
    liquids=filter(x-> x isa Liquid,collect(keys(ingredients)))
    S=length(solids)
    L=length(liquids)
    if L >=1 
        return Solution(ingredients)
    elseif S >=1
        return Mixture(ingredients)
    else 
        error("invalid combination of ingredients")
    end 
end 



function ingredients(c::Composition)
    return collect(keys(c.ingredients))
end 


function Base.show(io::IO,s::Composition)
    typstr=string(typeof(s))
    printstyled(io, "$typstr ($(length(collect(keys(s.ingredients)))) ingredient(s))\n";bold=true)
    ings=sort(ingredients(s))
    quants=round.(map(x->s.ingredients[x],ings);digits=3)
    show(io , DataFrame(Ingredient=ings,Concentration=quants);eltypes=false,summary=false,truncate=0,show_row_number=false,alignment=[:l,:l])
end 