struct Environment 
    atmosphere::Symbol
    temperature::Unitful.Temperature
    Environment(atmosphere,temperature)= atmosphere ∈ [:aeorbic,:anaerobic] ? new(atmosphere,temperature) : error("declared atmosphere must be :aerobic or :anaerobic")
end 