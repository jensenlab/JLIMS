struct Empty <: Composition 
end 

struct EmptyQuantity <: CompositionQuantity
    composition::Empty 
    quantity::Missing
end 


function *(e::Empty,m::Missing)
    return EmptyQuantity(e,m)
end 

function +(e1::EmptyQuantity,e2::EmptyQuantity)
    return EmptyQuantity(Empty(),missing)
end 

function +(e1::EmptyQuantity,m1::MixtureMass)
    return m1
end 


function +(m1::MixtureMass,e1::EmptyQuantity)
    return m1
end 


function +(s1::SolutionVolume,e1::EmptyQuantity)
    return s1
end 

function +(e1::EmptyQuantity,s1::SolutionVolume)
    return s1
end

function ingredients(empty::Empty)
    return Ingredient[]
end 