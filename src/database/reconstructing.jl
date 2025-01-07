
# recursively find the ledger ids at which we need to start reconstructing all of the locations we need for the entire reconstruction
function build_location_ledger_map(ll_map:::Dict{Integer,Integer},transfers::DataFrame;kwargs...)
    start=minimum(collect(values(ll_map)))
    ids=collect(keys(ll_map))
    for loc_id in ids
        ll_map[loc_id]=fetch_cache_ledger(loc_id,start) # push the head back until we hit a cache for each location
    end 
    
    new_start=minimum(collect(values(ll_map)))

    if new_start < start
        tfs=get_transfers(query_join_vector(ids),new_start,start;kwargs...) # get the intervening transfers 
        for i in nrow(transfers):1
            ledger_id=transfers[i,"LedgerID"]
            src=transfers[i,"Source"]
            ll_map[src]=ledger_id
        end 
        return build_location_ledger_map(ll_map,append!(tfs,transfers)) # re-build the location-ledger map after moving the head back
    else
        return ll_map, transfers
    end 
end 



function reconstruct_location(ids::Vector{Integer},ledger_id::Integer=get_last_ledger_id();encumbrances=false)

    ll_map=Dict(ids .=> (ledger_id,))
    ll_map, transfers= build_location_ledger_map(ll_map,DataFrame();ecumbrances=encumbrances)
    start=minimum(collect(values(ll_map)))
    all_locs=Dict{Integer,Location}()
    tracked_locs=collect_keys(ll_map)
    for loc_id in tracked_locs
        all_locs[loc_id]=fetch_cache(loc_id,ll_map[loc_id])
    end 
    for tf in eachrow(transfers) 
        source=tf["Source"]
        destination=tf["Destination"]
        quant=tf["Quantity"] * Unitful.uparse(tf["Unit"])
        if destination in tracked_locs
            transfer!(all_locs[source],all_locs[destination],quant)
        else
            withdraw!(all_locs[source],quant)
        end 
    end 
    out_locs=Location[]
    for id in ids 
        push!(out_locs,all_locs[id])
    end 
    return out_locs 
end 










function get_movements(entry::AbstractString,starting::Integer=0,ending::Integer=get_last_ledger_id();encumbrances=false)  # find all movements for a set of locations betweeen `starting` and `ending` ledger ids
    x=""
    if encumbrances 
        x= 
        """
        WITH RECURSIVE y (LedgerID,Child,Parent)
        AS(SELECT e.LedgerID, c.Child,c.Parent
            FROM (Select Max(ID), LedgerID, EncumbranceID, IsEnforced FROM EncumbranceEnforcement WHERE LedgerID BETWEEN $starting AND $ending GROUP BY EncumbranceID)  e INNER JOIN EncumberedMovements c ON e.EncumbranceID = c.EncumbranceID WHERE IsEnforced = 1
        UNION ALL 
            SELECT t.LedgerID, t.Child,t.Parent
            FROM Movements t) ,
        x (LedgerID,Child,Parent)
        AS(
         SELECT LedgerID, Child,Parent
            FROM y
            WHERE Child in $entry OR Parent in $entry
        UNION ALL
        SELECT y.LedgerID ,y.Child,y.Parent
            FROM y  ,x
            WHERE x.Source = y.Destination
        )
        SELECT DISTINCT  * FROM x WHERE  LedgerID BETWEEN $starting AND $ending ORDER BY LedgerID
        """
    else 
        x=
        """
        WITH RECURSIVE x (LedgerID,Child,Parent)
        AS(
        SELECT Transfers.LedgerID,Child,Parent
            FROM Transfers
            WHERE Child in $entry OR Parent in $entry
        UNION ALL
        SELECT t.LedgerID ,t.Source,t.Destination,t.Quantity,t.Unit
            FROM Transfers t  ,x
            WHERE x.Source = t.Destination
        )
        SELECT DISTINCT  * FROM x WHERE  LedgerID BETWEEN $starting AND $ending ORDER BY LedgerID
        """

    end 
return query_db(x)
end 


function get_transfers(entry::AbstractString,starting::Integer=0,ending::Integer=get_last_ledger_id();encumbrances=false)  # find all transfers for a set of locations betweeen `starting` and `ending` ledger ids
    x=""
    if encumbrances 
        x= 
        """
        WITH RECURSIVE y (LedgerID,Source,Destination,Quantity,Unit)
        AS(SELECT e.LedgerID, c.Source,c.Destination,c.Quantity,c.Unit
            FROM (Select Max(ID), LedgerID, EncumbranceID, IsEnforced FROM EncumbranceEnforcement WHERE LedgerID BETWEEN $starting AND $ending GROUP BY EncumbranceID)  e INNER JOIN EncumberedTransfers c ON e.EncumbranceID = c.EncumbranceID WHERE IsEnforced = 1
        UNION ALL 
            SELECT t.LedgerID, t.Source, t.Destination, t.Quantity, t.Unit 
            FROM Transfers t) ,
        x (LedgerID,Source,Destination,Quantity,Unit)
        AS(
         SELECT y.LedgerID, Source,Destination,y.Quantity,y.Unit
            FROM y
            WHERE Destination in $entry OR Source in $entry
        UNION ALL
        SELECT y.LedgerID ,y.Source,y.Destination,y.Quantity,y.Unit
            FROM y  ,x
            WHERE x.Source = y.Destination
        )
        SELECT DISTINCT  * FROM x WHERE  LedgerID BETWEEN $starting AND $ending ORDER BY LedgerID
        """
    else 
        x=
        """
        WITH RECURSIVE x (LedgerID,Source,Destination,Quantity,Unit)
        AS(
        SELECT Transfers.LedgerID, Source,Destination,Transfers.Quantity,Transfers.Unit
            FROM Transfers
            WHERE Destination in $entry OR Source in $entry
        UNION ALL
        SELECT t.LedgerID ,t.Source,t.Destination,t.Quantity,t.Unit
            FROM Transfers t  ,x
            WHERE x.Source = t.Destination
        )
        SELECT DISTINCT  * FROM x WHERE  LedgerID BETWEEN $starting AND $ending ORDER BY LedgerID
        """

    end 
return query_db(x)
end 


if nrow(cache_id)==1 # cache_id is a DataFrame with either 0 or 1 rows. 0 rows means no cache is stored anywhere in the database. 1 means there is a cache we can start from 
    cache_id=cache_info[1,1]
    cache_vals=query_db("SELECT * FROM CacheSets WHERE CacheID = $cache_id")[1,:]
    start= cache_info[1,2] # overwrite  which ledger id to start simulation from
    locked=Bool(cache_vals["IsLocked"])
    active=Bool(cache_vals["IsActive"])


    #parent 
    parent_id=cache_vals["ParentID"]
    if !ismissing(parent_id)
        if parent_depth=0 
            parent_info=query_db("SELECT * FROM Locations WHERE ID = $id")[1,:]
            loc.parent=LocationRef(parent_id,parent_info["Name"])
            if locked
                lock!(loc)
            end 
        else # start looking up the tree 
            parent=reconstruct_location(parent_id,start;encumbrances=encumbrances,cache_results=cache_results,parent_depth=max(parent_depth-1,0),child_depth=0)
            move_into!(parent,child,lock=locked)
        end
    end  


    #children 
    children_id=cache_vals["ChildSetID"]
    childset=query_db("SELECT * FROM CachedChildren WHERE ChildSetID= $children_id")
    if loc_type <: JLIMS.Labware
        for i in 1:nrow(childset)
            child_id=childset[i,"ChildID"]
            row=childset[i,"RowIdx"]
            col=childset[i,"ColIdx"]
            if child_depth=0 
                child_info=query_db("SELECT * FROM Locations WHERE ID = $id")[1,:]
                loc.children[row,col]=LocationRef(child_id,child_info["Name"])
            else
                child=reconstruct_location(child_id,start;encumbrances=encumbrances,cache_results=cache_results,parent_depth=0,child_depth=max(child_depth-1,0))
                loc.children[row,col]=child
                # dont worry about locking the child --it is a well, which means it is automatically locked to the labware 
            end 
        end 
    else # for other locations 
        for i in 1:nrow(childset)
            child_id=childset[i,"ChildID"]
            if child_depth=0 
                child_info=query_db("SELECT * FROM Locations WHERE ID = $id")[1,:]
                push!(loc.children,LocationRef(child_id,child_info["Name"]))
            else
                child=reconstruct_location(child_id,start;encumbrances=encumbrances,cache_results=cache_results,parent_depth=0,child_depth=max(child_depth-1,0))
                l=is_locked(child)
                unlock!(child) # the child may be locked on reconstruction but it really should be in the parent. Unlock to execut the move, but then set the locked state back to its original value after the move.
                move_into(loc,child;lock=l)
            end 
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
end # cache reconstruction