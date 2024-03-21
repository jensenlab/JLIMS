# reagents are physical instances of ingredients. Physical items have a labware, and position

struct Reagent 
    id::String # a uuid 
    ingredient::Ingredient 
    amount::Unitful.Quantity
    labware::Labware 
    position::Integer 
    Reagent(id,ingredient,amount,labware,position) = dimension(amount) in map(x->dimension(x), [u"percent",u"mol",u"g"]) ? new(id,ingredient,amount,labware,position) : error("amount must have a valid dimension")
end 

Reagent(ingredient,amount,labware,position)= Reagent(id(ingredient.id),ingredient,amount,labware,position) 



