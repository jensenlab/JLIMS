abstract type Instrument <: Location
    abstract type ReagentHandler <: Instrument 
        abstract type Human <: ReagentHandler
        abstract type LiquidHandler <: ReagentHandler
    abstract type Incubator <: Instrument 
    abstract type Centrifuge <: Instrument 
            
    

    
