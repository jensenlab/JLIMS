abstract type Labware <: Location end 


macro labware(name, type, welltype, plate_shape,vendor,catalog)
    n=Symbol(name)
    t=Symbol(type)
    wt=Symbol(welltype)
    ps::Tuple{Integer,Integer}=eval(plate_shape)
    v::String=string(vendor)
    c::String=string(catalog)
    if isdefined(__module__,n) || isdefined(JLIMS,n)
        throw(ArgumentError("Labware  $n already exists"))
    end 
    if !isdefined(__module__,t) && !isdefined(JLIMS,t)
        throw(ArgumentError("abstract labware type $t does not exist."))
    end 
    return esc(quote
    import JLIMS: shape,vendor,catalog,occupancy_cost,parent_cost
    import AbstractTrees.ParentLinks
    export $n
    mutable struct $n <: ($t)
        const id::Base.Integer
        const name::Base.String
        parent::Union{JLIMS.Location,Nothing}
        const children::Matrix{$wt}
        is_locked::Bool
        ($n)(id,name=string(UUIDs.uuid4()),parent=nothing,children=Matrix{$wt}(undef,$ps...),is_locked=false)=new(id,name,parent,children,is_locked)
    end  
    JLIMS.shape(x::$n)= Base.size(AbstractTrees.children(x)) 
    JLIMS.vendor(::$n)=$v
    JLIMS.catalog(::$n)=$c
    AbstractTrees.ParentLinks(::Type{<:$(n)})=AbstractTrees.StoredParents()
    JLIMS.parent_cost(::($n))=2//1 # occupancy cost is greater than 1. The value of 2//1 was chosen arbitrarily the new location is not allowed to be a parent unless otherwise specified
    JLIMS.occupancy_cost(::($n),::($wt))= 1//Base.prod($ps...) # !!!Exception!!! the plate can hold up to prod(ps...) wells of type wt. 
    end)
end 


function alphabet_code(n) 
    
    alphabet=collect('A':'Z')
    k=length(alphabet)
    return repeat(alphabet[mod(n-1,k)+1],cld(n,k))
end 


function generate_labware(lw_type::Type{<:Labware},current_idx::Integer)
    lw=lw_type(current_idx)
    sh=shape(lw)
    welltype=eltype(children(lw))
    current_idx+=1
    for col in 1:sh[2]
        for row in 1:sh[1]
            lw.children[row,col]=welltype(current_idx,alphabet_code(row)*string(col),lw,true)
            
            current_idx+=1
        end 
    end
    return lw
end 

wells(x::Labware) = children(x)