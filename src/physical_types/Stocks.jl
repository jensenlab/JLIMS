struct Stock 
    id::String 
    solution::Solution 
    volume::Unitful.Quantity 
    labware::labware
    position::Integer
    Stock(id,solution,volume,labware,position,expires) = dimension(volume) == dimension(u"L") && ustrip(volume) >=0 ? new(id,solution,volume,labware,position): error("volume must have a valid dimension and be nonnegative")
end 


Stock(solution,volume,labware,position) = Stock(id(),solution,volume,labware,position) 
