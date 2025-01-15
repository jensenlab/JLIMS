function cache(loc::Location,sequence_id=get_last_sequence_id())
    parent_id=location_id(parent(loc))
    if isnothing(parent_id)
        parent_id="NULL"
    end
    children_id=cache_children(children(loc))
    stock_id=cache(stock(loc))
    attr_id=cache(attributes(loc))
    locked=Int(is_locked(loc))
    active=Int(is_active(loc))
    id=query_db("SELECT ID FROM CacheSets WHERE ParentID = $parent_id AND ChildSetID = $children_id AND AttributeSetID = $attr_id AND StockID = $stock_id AND IsLocked = $locked AND IsActive =$active")
    if nrow(id)==0 
        execute_db("INSERT INTO CacheSets(ParentID,ChildSetID,AttributeSetID, StockID,IsLocked,IsActive) Values($parent_id,$children_id,$attr_id,$stock_id,$locked,$active)")
        id=query_db("SELECT Max(ID) FROM CacheSets")[1,1]
    else
        id=id[1,1]
    end
    loc_id=location_id(loc)
    ledger_id= upload_ledger(sequence_id)
    execute_db("INSERT INTO Caches(LocationID,CacheSetID,LedgerID) Values($loc_id,$id,$ledger_id)")
    return nothing
end 




function get_stock_id(s::Stock)
    id=query_db("SELECT ID FROM CachedStocks WHERE StockHash = $(hash(s))") # search to see if stock is in the database
    if nrow(id)==1 
        return id[1,1]
    else 
        return nothing 

    end
end 

function get_component_id(comp::Union{Chemical,Strain})
    id=query_db("SELECT * FROM Components WHERE ComponentHash = $(hash(comp)) " ) 
    if nrow(id)==1
        return id[1,1] # return the id if it exists
    else
        return upload_component(comp) # if not, upload a new component--this function also returns the id 
    end 
end 



function cache(s::Stock)
    id=get_stock_id(s)
    if isnothing(id) 
        execute_db("INSERT OR IGNORE INTO CachedStocks(StockHash) Values($(hash(s)))") # upload the hash as a new id 
        id=get_stock_id(s)
        sols=solids(s)
        for solid in chemicals(sols)
            sol_id=get_component_id(solid)
            quant=sols[solid]
            execute_db("INSERT OR IGNORE INTO CachedComponents(StockID,ComponentID,Quantity,Unit) Values($id,$sol_id,$(ustrip(quant)),'$(string(unit(quant)))')")
        end 
        liqs=liquids(s)
        for liquid in chemicals(liqs)
            liq_id=get_component_id(liquid)
            quant=liqs[liquid]
            execute_db("INSERT OR IGNORE INTO CachedComponents(StockID,ComponentID,Quantity,Unit) Values($id,$liq_id,$(ustrip(quant)),'$(string(unit(quant)))')")
        end
        for org in organisms(s)
            org_id=get_component_id(org)  # uploads a new organism if necessary 
            execute_db("INSERT INTO CachedComponents(StockID,ComponentID) Values($id,$org_id)")
        end
        return id 

    else
        return id
    end 

end 

function get_attribute_set_id(a::AttributeDict)
    id=query_db("SELECT ID FROM CachedAttributeSets WHERE AttributeSetHash = $(hash(a))") # search to see if attribute set is in the database
    if nrow(id)==1 
        return id[1,1]
    else 
        return nothing 
    
    end
end 




function cache(a::AttributeDict)
    id=get_attribute_set_id(a)
    if isnothing(id)
        execute_db("INSERT OR IGNORE INTO CachedAttributeSets(AttributeSetHash) Values($(hash(a)))") # upload the hash as a new id 
        id=get_attribute_set_id(a)
        attrs=collect(keys(a))
        for attr in attrs 
            val=value(a[attr])
            upload_attribute(attr)
            execute_db("INSERT OR IGNORE INTO CachedAttributes(AttributeSetID,AttributeID,Value,Unit) Values($id,'$(string(attr))',$(ustrip(val)),'$(string(unit(val)))')")
        end 
    end 
    return id 
end 


function get_child_set_id(c)
    ids=location_id.(c)
    id=query_db("SELECT ID FROM CachedChildSets WHERE ChildSetHash = $(hash(ids))") # search to see if attribute set is in the database
    if nrow(id)==1 
        return id[1,1]
    else 
        return nothing 
    
    end
end 


function cache_children(c::Matrix{Union{LocationRef,T}}) where T<:Well 
    loc_ids=location_id.(c)
id=get_child_set_id(c)
if isnothing(id)
    execute_db("INSERT OR IGNORE INTO CachedChildSets(ChildSetHash) Values($(hash(loc_ids)))")
    id=get_child_set_id(c)
    rows,cols=size(c)
    for col in 1:cols
        for row in 1:rows
            execute_db("INSERT OR IGNORE INTO CachedChildren(CachedChildSetID,ChildID,RowIdx,ColIdx) Values($id,$(location_id(c[row,col])), $row,$col)")
        end
    end 
end
return id 
end 

function cache_children(c::Vector{<:Union{LocationRef,Location}})
    loc_ids=location_id.(c)
    id=get_child_set_id(c)
    if isnothing(id)
        execute_db("INSERT OR IGNORE INTO CachedChildSets(ChildSetHash) Values($(hash(loc_ids)))")
        id=get_child_set_id(c)
        for child in c 
            execute_db("INSERT OR IGNORE INTO CachedChildren(CachedChildSetID,ChildID) Values($id,$(location_id(child)))")
        end
    end
    return id 
end 

function cache_children(c::Tuple{})
    loc_ids=location_id.(c)
    id=get_child_set_id(c)
    if isnothing(id)
        execute_db("INSERT OR IGNORE INTO CachedChildSets(ChildSetHash) Values($(hash(loc_ids)))")
        id=get_child_set_id(c)
        for child in c 
            execute_db("INSERT OR IGNORE INTO CachedChildren(CachedhildSetID,ChildID) Values($id,$(location_id(child)))")
        end
    end
    return id 
end 




