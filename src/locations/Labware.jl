


"""
    @labware name supertype loctype shape vendor catalog 

Define a new labware Type `name` and overload methods to make `name` a JLIMS compatible labware. 
"""
macro labware(name, supertype, childtype, shape,vendor,catalog)
    n=Symbol(name)
    t=supertype
    #ps::Tuple{Integer,Integer}=eval(shape)
    ps=shape
    v::String=string(vendor)
    c::String=string(catalog)
    wt=childtype
    if isdefined(__module__,n) || isdefined(JLIMS,n)
        throw(ArgumentError("Labware  $n already exists"))
    end 
    return esc(quote
    import JLIMS: shape,vendor,catalog,occupancy_cost,parent_cost,childtype
    import AbstractTrees.ParentLinks
    export $n
    mutable struct $n <: ($t)
        const location_id::Base.Integer
        const name::Base.String
        parent::Union{JLIMS.Location,Nothing,JLIMS.LocationRef}
        const children::Matrix{Union{$wt,JLIMS.LocationRef}}
        attributes::AttributeDict
        is_locked::Bool
        is_active::Bool
        ($n)(id::Integer,name::String=string(UUIDs.uuid4()),parent=nothing,children=Matrix{Union{$wt,JLIMS.LocationRef}}(undef,$ps...),attributes=AttributeDict(),is_locked=false,is_active=true)=new(id,name,parent,children,attributes,is_locked,is_active)
    end  
    JLIMS.shape(x::$n)= Base.size(AbstractTrees.children(x)) 
    JLIMS.vendor(::$n)=$v
    JLIMS.catalog(::$n)=$c
    JLIMS.childtype(::$n)=$wt
    AbstractTrees.ParentLinks(::Type{<:$(n)})=AbstractTrees.StoredParents()
    JLIMS.parent_cost(::($n))=2//1 # occupancy cost is greater than 1. The value of 2//1 was chosen arbitrarily the new location is not allowed to be a parent unless otherwise specified
    JLIMS.occupancy_cost(::($n),::($wt))= 1//Base.prod($ps) # !!!Exception!!! the plate can hold up to prod(ps...) wells of type wt. 
    end)
end 






wells(x::Labware) = children(x)