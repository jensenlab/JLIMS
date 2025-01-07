function get_location_info(id::Integer)
    loc_info=query_db("SELECT * FROM Locations WHERE ID =$id")
    if nrow(loc_info) == 0 
        error("location id not found")
    end 
    out=loc_info[1,:]
    return string(out["Name"]),eval(Symbol(out["Type"]))
end 




function fetch_cache(id::Integer,ledger_id::Integer)

    loc_name,loc_type=get_location_info(id)
    # initialize the location. all locations can be created with just a name and an ID 
    loc=loc_type(id,loc_name)


    cache_info=query_db("SELECT ID, LocationID, CacheSetID, Max(LedgerID) FROM Caches WHERE LocationID = $id AND LedgerID <= $ledger_id")


    if nrow(cache_info)==1 # cache_id is a DataFrame with either 0 or 1 rows. 0 rows means no cache is stored anywhere in the database. 1 row  means there are caches we can start from 
        cache_set_id=cache_info[1,"CacheSetID"]
        out_ledger=cache_info[1,"Max(LedgerID)"]
        cache_vals=query_db("SELECT * FROM CacheSets WHERE ID =$cache_set_id")[1,:] 
        locked=Bool(cache_vals["IsLocked"])
        active=Bool(cache_vals["IsActive"])


        #parent 
        parent_id=cache_vals[:"ParentID"]
        if !ismissing(parent_id)
            n,t=get_location_info(parent_id)
            loc.parent=LocationRef(parent_id,n,t)
        end 


        #children 
        children_id=cache_vals["ChildSetID"]
        childset=query_db("SELECT * FROM CachedChildren WHERE ChildSetID= $children_id")
        if loc_type <: JLIMS.Labware
            for i in 1:nrow(childset)
                child_id=childset[i,"ChildID"]
                row=childset[i,"RowIdx"]
                col=childset[i,"ColIdx"]
                n,t=get_location_info(child_id)
                loc.children[row,col]=LocationRef(child_id,n,t)
            end 
        else # for other locations 
            for i in 1:nrow(childset)
                child_id=childset[i,"ChildID"]
                n,t=get_location_info(child_id)
                push!(loc.children,LocationRef(child_id,n,t))
            end
        end 

                


        #attrs 
        attr_id=cache_vals["AttributeSetID"]
        attr_set=query_db("SELECT * FROM CachedAttributes WHERE AttributeSetID = $attr_id")
        ad=AttributeDict() 
        for i in nrow(attr_set)
            attr=eval(Symbol(attr_set[i,"AttributeID"]))
            val=attr_set[i,"Value"]
            un=attr_set[i,"Unit"]

            ad[attr]=attr(val*Unitful.uparse(un))
        end 
        loc.attributes=ad 


        #stock 
        if loc_type <: JLIMS.Well 
            stock_id=cache_vals["StockID"]
            stock_info=query_db("SELECT * FROM CachedComponents WHERE StockID = $stock_id")
            st=Empty()
            for row in eachrow(stock_info)
                comp=get_component(row["ComponentID"])
                if comp isa JLIMS.Chemical 
                    st += row["Quantity"]*Unitful.uparse(row["Unit"])*comp
                elseif comp isa JLIMS.Strain 
                    st += comp 
                end 
            end 
            loc.stock=st 
        end 


        return loc ,out_ledger
    else # no cache found, start with the empty location from ledger id 1-> the very beginning.
        return loc, 1 

    end 
end 


function fetch_cache_ledger(id::Integer,ledger_id::Integer)
    loc_name,loc_type=get_location_info(id)
    # initialize the location. all locations can be created with just a name and an ID 
    loc=loc_type(id,loc_name)

    start =1
    cache_info=query_db("SELECT ID, LocationID, CacheSetID, Max(LedgerID) FROM Caches WHERE LocationID = $id AND LedgerID <= $ledger_id")
    if nrow(cache_info)==1 # cache_id is a DataFrame with either 0 or 1 rows. 0 rows means no cache is stored anywhere in the database. 1 row  means there are caches we can start from 
        start =cache_info[1,"Max(LedgerID)"]
    end 
    return start 
end 