struct Dispense 
    source::Stock
    destination::Stock 
    quantity::Unitful.Quantity
    instrument::String
    channel::Integer 
    time::DateTime
end 