abstract type Instrument <: Location
    abstract type ReagentHandler <: Instrument 
        abstract type Human <: ReagentHandler
        abstract type LiquidHandler <: ReagentHandler
    abstract type Incubator <: Instrument 
    abstract type Centrifuge <: Instrument 
            
    

    
#=
    macro instrument(name, type, capacity, plate_shape,vendor,catalog)
        n=Symbol(name)
        t=Symbol(type)
        v=string(vendor)
        c=string(catalog)
        if isdefined(__module__,n) || isdefined(JLIMS,n)
            error("Labware type $n already exists")
        end 
        if !isdefined(__module__,t) && !isdefined(JLIMS,t)
            error("abstract labware type $t does not exist.")
        end 
        if !(eval(capacity) isa Unitful.Volume) 
            error("capacity must be a volume")
        end 
        if !(eval(plate_shape) isa Tuple{Integer,Integer})
            error("plate shapse must be a `Tuple{Integer,Integer}")
        end 
        return esc(quote
        import JLIMS: wellcapacity,shape,vendor,catalog
        export $n,wellcapacity,shape,vendor,catalog
        struct $n <: (JLIMS.$t)
            id::Base.Integer
            parent::Union{JLIMS.Location,Missing}
        end 
        JLIMS.wellcapacity(::$n)= $capacity 
        JLIMS.shape(::$n)= $plate_shape 
        JLIMS.vendor(::$n)=$v
        JLIMS.catalog(::$n)=$c
        end)
    end 
    =#