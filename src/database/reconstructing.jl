
# recursively find the ledger ids at which we need to start reconstructing all of the locations we need for the entire transfer reconstruction
function build_location_ledger_map(ll_map::Dict{T,T},transfers::DataFrame,head::T,time::DateTime;kwargs...) where T <: Integer
    startmap=deepcopy(ll_map)
    ids=collect(keys(ll_map))
    for loc_id in ids
        ledger,cache_set_id=fetch_cache_ledger(loc_id,ll_map[loc_id],time;kwargs...)
        if ledger < ll_map[loc_id]
            ll_map[loc_id]=T(ledger)
        end
        if !ismissing(cache_set_id)
            cache_vals=query_db("SELECT * FROM CacheSets WHERE ID =$cache_set_id")[1,:] 
            parent_id=cache_vals["ParentID"]
            if !ismissing(parent_id)
                if !haskey(ll_map,parent_id) || ll_map[parent_id] > ledger 
                    ll_map[T(parent_id)]=T(ledger)
                end
            end 
        end 
    end 

    
    foot=minimum(collect(values(ll_map)))
   
    if startmap != ll_map 
        tfs=get_transfers(ids,foot,head,time;kwargs...)# get the intervening transfers 
        for row in reverse(eachrow(tfs))
            sequence_id=row["Max(SequenceID)"]
            src=row["Source"]
            if (sequence_id-1) < ll_map[src] 
                ll_map[T(src)]=T(sequence_id-1)
            end
        end 
        mvts=get_movements_as_child(query_join_vector(ids),foot,head,time;kwargs...)
        for row in reverse(eachrow(mvts))
            sequence_id=row["Max(SequenceID)"]
            prt=row["Parent"]
            if !ismissing(prt)
                if !haskey(ll_map,prt) || (sequence_id-1) < ll_map[prt] 
                    ll_map[T(prt)]=T(sequence_id-1)
                end
            end 
        end 

        return build_location_ledger_map(ll_map,unique!(append!(tfs,transfers)),head,time;kwargs...) # re-build the location-ledger map after moving the foot back
    else
        return ll_map, transfers
    end 
end 
function get_attribute(attr::String)
    return eval(Symbol(attr))
end

function get_component(id::Integer)
    comp_type=query_db("SELECT Type FROM Components WHERE ID=$id")
    if nrow(comp_type)==0
        error("component $id does not exist in the database")
    else 
        comp_type=comp_type[1,1]
    end 

    if comp_type == "Chemical" 
        c = query_db("SELECT Name, Type,MolecularWeight,Density,CID FROM Chemicals WHERE ComponentID = $id")[1,:]
        typ=eval(Symbol(c["Type"]))
        return typ(c["Name"],c["MolecularWeight"]*u"g/mol",c["Density"]*u"g/mL",c["CID"])

    elseif comp_type =="Strain"
        c= query_db("SELECT Genus, Species, Strain FROM Strains WHERE ComponentID = $id")[1,:]
        return Strain(c["Genus"],c["Species"],c["Strain"])
    else
        error("component $id not found in the database")
        return nothing
    end 
end


function get_location_info(id::Integer)
    loc_info=query_db("SELECT * FROM Locations WHERE ID =$id")
    if nrow(loc_info) == 0 
        error("location id not found")
    end 
    out=loc_info[1,:]
    return string(out["Name"]), eval(Symbol(out["Type"]))
end 

function get_cache(loc_id::Integer,sequence_id::Integer,time::DateTime,encumbrances::Bool)
    ledger_time=db_time(time)
    if encumbrances
        return query_db("
        WITH ledger_subset (ID,SequenceID,Time)
        AS(
            SELECT ID,SequenceID,Max(Time) FROM Ledger WHERE Time <= $ledger_time AND SequenceID BETWEEN $starting AND $ending GROUP BY SequenceID
            )
        
        WITH y (ID,LocationID,CacheSetID,LedgerID)
        AS(SELECT v.ID, v.LocationID, v.CacheSetID, e.LedgerID
            FROM (Select ID, Max(SequenceID), LedgerID, EncumbranceID, IsEnforced FROM EncumbranceEnforcement INNER JOIN ledger_subset ON EncumbranceEnforcement.LedgerID = ledger_subset.ID  GROUP BY EncumbranceID)  e INNER JOIN EncumberedCaches v ON e.EncumbranceID = v.EncumbranceID WHERE IsEnforced = 1
        UNION ALL 
            SELECT c.ID, c.LocationID,c.CacheSetID,c.LedgerID
            FROM Caches c) 
            SELECT ID, LocationID, CacheSetID, LedgerID, Max(SequenceID) FROM y INNER JOIN ledger_subset ON y.LedgerID = ledger_subset.ID WHERE LocationID = $loc_id")[1,:]
    else
        return query_db("
            WITH ledger_subset (ID,SequenceID,Time)
        AS(
            SELECT ID,SequenceID,Max(Time) FROM Ledger WHERE Time <= $ledger_time AND SequenceID BETWEEN $starting AND $ending GROUP BY SequenceID
            ) 
        
        SELECT ID, LocationID, CacheSetID, LedgerID, Max(SequenceID) FROM Caches INNER JOIN ledger_subset ON Caches.LedgerID = ledger_subset.ID WHERE LocationID = $loc_id")[1,:]
    end 
end



function fetch_cache(loc_id::Integer, sequence_id::Integer,time::DateTime=Dates.now();encumbrances=false)
    n,t=get_location_info(loc_id)
    loc= t(loc_id,n)
    cache_info=DataFrame()
   
    cache_info=get_cache(loc_id,sequence_id,time,encumbrances)
    
    cache_set_id=cache_info["CacheSetID"]
    if !ismissing(cache_set_id) # cache_id is a DataFrame with either 0 or 1 rows. 0 rows means no cache is stored anywhere in the database. 1 row  means there are caches we can start from 
        out_ledger=cache_info["Max(LedgerID)"]
        cache_vals=query_db("SELECT * FROM CacheSets WHERE ID =$cache_set_id")[1,:] 
        locked=Bool(cache_vals["IsLocked"])
        active=Bool(cache_vals["IsActive"])


        #parent 
        parent_id=cache_vals["ParentID"]
        if !ismissing(parent_id)
            n,t=JLIMS.get_location_info(parent_id)
            loc.parent=JLIMS.LocationRef(parent_id,n,t)
        end 


        #children 
        children_id=cache_vals["ChildSetID"]
        childset=query_db("SELECT * FROM CachedChildren WHERE CachedChildSetID= $children_id")
        if typeof(loc) <: JLIMS.Labware
            for i in 1:nrow(childset)
                child_id=childset[i,"ChildID"]
                row=childset[i,"RowIdx"]
                col=childset[i,"ColIdx"]
                n,t=JLIMS.get_location_info(child_id)
                loc.children[row,col]=JLIMS.LocationRef(child_id,n,t)
            end 
        else # for other locations 
            for i in 1:nrow(childset)
                child_id=childset[i,"ChildID"]
                n,t=JLIMS.get_location_info(child_id)
                add_to!(loc,JLIMS.LocationRef(child_id,n,t))
            end
        end 

                


        #attrs 
        attr_id=cache_vals["AttributeSetID"]
        attr_set=query_db("SELECT * FROM CachedAttributes WHERE AttributeSetID = $attr_id")
        ad=AttributeDict() 
        for i in 1:nrow(attr_set)
            attr=get_attribute(attr_set[i,"AttributeID"])
            val=attr_set[i,"Value"]
            un=attr_set[i,"Unit"]

            ad[attr]=attr(val*Unitful.uparse(un))
        end 
        loc.attributes=ad 


        #stock 
        if typeof(loc) <: JLIMS.Well 
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


        return (loc ,out_ledger)
    else # no cache found, start with the empty location from ledger id 1-> the very beginning.
        return (loc, 1) 
    end 
end

function fetch_cache_ledger(id::Integer,sequence_id::Integer,time::DateTime=Dates.now();encumbrances=false)
    start =1
    cache_info=get_cache(id,sequence_id,time,encumbrances)
    cache_set_id=cache_info["CacheSetID"]
    if !ismissing(cache_set_id) # cache_id is a DataFrame with either 0 or 1 rows. 0 rows means no cache is stored anywhere in the database. 1 row  means there are caches we can start from 
        start =cache_info["Max(SequenceID)"]
    end 
    return start ,cache_set_id
end 

function reconstruct_location(ids::Vector{<:Integer},sequence_id::Integer=get_last_sequence_id(),time::DateTime=Dates.now();encumbrances=false,cache_results=false)

    ll_map=Dict(ids .=> (sequence_id,))
    ll_map, transfers= build_location_ledger_map(ll_map,DataFrame(),sequence_id,time;encumbrances=encumbrances)
    foot=minimum(collect(values(ll_map)))
    all_locs=Dict{Integer,Location}()
    tracked_locs=collect(keys(ll_map))
    for loc_id in tracked_locs
        loc,ledger=fetch_cache(loc_id,ll_map[loc_id],time)
  
        all_locs[loc_id]=loc
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

    # establish_parent_links 
    for loc_id in tracked_locs 
        par_id= location_id(parent(all_locs[loc_id]))
        if !isnothing(par_id)
            all_locs[loc_id].parent =all_locs[par_id]
        end 
    end 

    out_locs=Location[]
    current_children=Dict{Integer,Integer}()
    for id in tracked_locs
        loc=all_locs[id]
        for child in children(loc)
            current_children[location_id(child)]=id
        end
    end 

    movements=get_movements(tracked_locs,current_children,foot,sequence_id,time;encumbrances=encumbrances)
    for row in eachrow(movements) 
        if row.Child in tracked_locs
            all_locs[row.Child].parent = all_locs[row.Parent]

        elseif row.Parent in tracked_locs
            n,t=get_location_info(row.Child)
            add_to!(all_locs[row.Parent],LocationRef(row.Child,n,t))
        else
            current_parent=current_children[row.Child]
            n,t=get_location_info(row.Child)
            remove!(all_locs[current_parent],LocationRef(row.Child,n,t))
        end 
    end 

    environments=get_environments(tracked_locs,foot,sequence_id,time;encumbrances=encumbrances)

    for row in eachrow(environments)
        attr=get_attribute(row.Attribute)
        quant=row.Value*Unitful.uparse(row.Unit)
        set_attribute!(all_locs[row.LocationID],attr(quant))
    end 

    for id in ids 
        push!(out_locs,all_locs[id])
    end 

    if cache_results && !encumbrances # encumbrances would invalidate the caches 
        cache.(out_locs,(sequence_id,))
    elseif cache_results 
        @warn "Results not cached because they include encumbrances"
    end 

    return out_locs 
end 



function reconstruct_location(id::Integer,sequence_id::Integer=get_last_sequence_id(),time::DateTime=Dates.now();encumbrances=false,cache_results=false)
    return reconstruct_location([id],sequence_id,time;encumbrances=encumbrances,cache_results=cache_results)[1]
end







function get_movements_as_parent(entry::AbstractString,starting::Integer=0,ending::Integer=get_last_sequence_id(),time::DateTime=Dates.now();encumbrances=false)  # find all movements for a set of locations betweeen `starting` and `ending` ledger ids
    ledger_time = db_time(time)
    x=""
    if encumbrances 
        x=
        """
            WITH ledger_subset (ID,SequenceID,Time)
        AS(
            SELECT ID,SequenceID,Max(Time) FROM Ledger WHERE Time <= $ledger_time AND SequenceID BETWEEN $starting AND $ending GROUP BY SequenceID
            ) 

        WITH y (LedgerID,Parent,Child)
        AS(SELECT e.LedgerID, v.Parent,v.Child
            FROM (Select ID, Max(SequenceID), LedgerID, EncumbranceID, IsEnforced FROM EncumbranceEnforcement INNER JOIN ledger_subset ON EncumbranceEnforcement.LedgerID = ledger_subset.ID  GROUP BY EncumbranceID)  e INNER JOIN EncumberedMovements v ON e.EncumbranceID = v.EncumbranceID WHERE IsEnforced = 1
        UNION ALL 
            SELECT c.LedgerID,c.Parent,c.Child
            FROM Movements c) 
        SELECT  LedgerID, Max(SequenceID),Parent,Child FROM y INNER JOIN ledger_subset ON y.LedgerID = ledger_subset.ID WHERE  Parent in $entry GROUP BY Child ORDER BY SequenceID
        """
    else
        x=
        """
            WITH ledger_subset (ID,SequenceID,Time)
        AS(
            SELECT ID,SequenceID,Max(Time) FROM Ledger WHERE Time <= $ledger_time AND SequenceID BETWEEN $starting AND $ending GROUP BY SequenceID
            ) 
        SELECT  LedgerID, Max(SequenceID),Parent,Child FROM Movements INNER JOIN ledger_subset ON Movements.LedgerID = ledger_subset.ID WHERE  Parent in $entry GROUP BY Child ORDER BY SequenceID
        """
    end
    return query_db(x)
end 

function get_movements_as_child(entry::AbstractString,starting::Integer=0,ending::Integer=get_last_sequence_id()time::DateTime=Dates.now();encumbrances=false)
    ledger_time=db_time(time)
    x=""
    if encumbrances 
        x=
        """
            WITH ledger_subset (ID,SequenceID,Time)
        AS(
            SELECT ID,SequenceID,Max(Time) FROM Ledger WHERE Time <= $ledger_time AND SequenceID BETWEEN $starting AND $ending GROUP BY SequenceID
            ) 
        WITH y (LedgerID,Parent,Child)
        AS(SELECT e.LedgerID, v.Parent,v.Child
            FROM (Select ID, Max(SequenceID), LedgerID, EncumbranceID, IsEnforced FROM EncumbranceEnforcement INNER JOIN ledger_subset ON EncumbranceEnforcement.LedgerID = ledger_subset.ID  GROUP BY EncumbranceID)  e INNER JOIN EncumberedMovements v ON e.EncumbranceID = v.EncumbranceID WHERE IsEnforced = 1
        UNION ALL 
            SELECT c.LedgerID,c.Parent,c.Child
            FROM Movements c) 
        SELECT  LedgerID,Max(SequenceID),Parent,Child FROM yINNER JOIN ledger_subset ON y.LedgerID = ledger_subset.ID WHERE  Child in $entry  GROUP BY Child  ORDER BY SequenceIDD
        """
    else
        x=
        """
            WITH ledger_subset (ID,SequenceID,Time)
        AS(
            SELECT ID,SequenceID,Max(Time) FROM Ledger WHERE Time <= $ledger_time AND SequenceID BETWEEN $starting AND $ending GROUP BY SequenceID
            ) 

        SELECT  LedgerID,Max(SequenceID),Parent,Child FROM Movements INNER JOIN ledger_subset ON Movements.LedgerID = ledger_subset.ID WHERE  Child in $entry  GROUP BY Child  ORDER BY SequenceID
        """
    end
    return query_db(x)
end 



function get_movements(locs::Vector{<:Integer},current_children::Dict{Integer,Integer},starting::Integer=0,ending::Integer=get_last_sequence_id(),time::DateTime=Dates.now();encumbrances=false)
    ledger_time= db_time(time)
    loc_vec=query_join_vector(locs)
    loc_plus_children=query_join_vector(unique(vcat(locs,collect(keys(current_children)))))
    a=get_movements_as_child(loc_plus_children,starting,ending;encumbrances=encumbrances)
    b=get_movements_as_parent(loc_vec,starting,ending;encumbrances=encumbrances)
    b_child=filter(x->!ismissing(x),b.Child)
    c=DataFrame(SequenceID=Int[],Parent=Int[],Child=Int[])
    rename!(c, :SequenceID => :("Max(SequenceID)"))
    if length(b_child) > 0 
        c=get_movements_as_child(query_join_vector(b_child),starting,ending;encumbrances=encumbrances)
    end

    child_a=filter(:Child => (x -> !in(x,locs)) , a)
    final_movements=filter( :Child => x -> in(x,locs), a)

    for row in eachrow(child_a)
        if row.Parent != current_children[row.Child] # was the child originally in this parent? 
            push!(final_movements,row)
        end 
    end 

    new_children=filter(:Parent => x -> x in locs,c)

    
    final_movements=vcat(final_movements,new_children)
    rename!(final_movements , :("Max(SequenceID)") => :SequenceID)
    sort!(final_movements,:SequenceID)
    
    return final_movements
end


function get_transfers(locs::Vector{<:Integer},starting::Integer=0,ending::Integer=get_last_sequence_id(),time::DateTime=Dates.now();encumbrances=false)  # find all transfers for a set of locations betweeen `starting` and `ending` ledger ids
    ledger_time= db_time(time)
    entry=query_join_vector(locs)
    x=""
    if encumbrances 
        x= 
        """
                    WITH ledger_subset (ID,SequenceID,Time)
        AS(
            SELECT ID,SequenceID,Max(Time) FROM Ledger WHERE Time <= $ledger_time AND SequenceID BETWEEN $starting AND $ending GROUP BY SequenceID
            ) 

        WITH RECURSIVE y (LedgerID,Source,Destination,Quantity,Unit)
        AS(SELECT e.LedgerID, c.Source,c.Destination,c.Quantity,c.Unit
            FROM (Select ID, Max(SequenceID), LedgerID, EncumbranceID, IsEnforced FROM EncumbranceEnforcement INNER JOIN ledger_subset ON EncumbranceEnforcement.LedgerID = ledger_subset.ID  GROUP BY EncumbranceID)  e INNER JOIN EncumberedTransfers c ON e.EncumbranceID = c.EncumbranceID WHERE IsEnforced = 1
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
        SELECT DISTINCT  * FROM x INNER JOIN ledger_subset ON x.LedgerID = ledger_subset.ID  ORDER BY SequenceID
        """
    else 
        x=
        """
            WITH ledger_subset (ID,SequenceID,Time)
        AS(
            SELECT ID,SequenceID,Max(Time) FROM Ledger WHERE Time <= $ledger_time AND SequenceID BETWEEN $starting AND $ending GROUP BY SequenceID
            ) 

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
        SELECT DISTINCT  * FROM x INNER JOIN ledger_subset ON x.LedgerID = ledger_subset.ID  ORDER BY SequenceID
        """

    end 
return query_db(x)
end 


function get_environments(locs::Vector{<:Integer},starting::Integer=0,ending::Integer=get_last_sequence_id(), time::DateTime=Dates.now();encumbrances=false)
    ledger_time= db_time(time)
    entry=query_join_vector(locs)
    x=""
    if encumbrances 
        x=
        """
        WITH ledger_subset (ID,SequenceID,Time)
        AS(
            SELECT ID,SequenceID,Max(Time) FROM Ledger WHERE Time <= $ledger_time AND SequenceID BETWEEN $starting AND $ending GROUP BY SequenceID
            ), 
        
        y (LedgerID,LocationID,Attribute,Value,Unit)
        AS(SELECT e.LedgerID, v.LocationID,v.Attribute,v.Value,v.Unit
            FROM (Select ID, Max(SequenceID), LedgerID, EncumbranceID, IsEnforced FROM EncumbranceEnforcement INNER JOIN ledger_subset ON EncumbranceEnforcement.LedgerID = ledger_subset.ID  GROUP BY EncumbranceID)  e INNER JOIN EncumberedEnvironments v ON e.EncumbranceID = v.EncumbranceID WHERE IsEnforced = 1
        UNION ALL 
            SELECT c.LedgerID,c.LocationID,c.Attribute,c.Value,c.Unit
            FROM EnvironmentAttributes c) 
            


        SELECT  LedgerID,Max(SequenceID),LocationID,Attribute,Value,Unit FROM y INNER JOIN ledger_subset ON y.LedgerID = ledger_subset.ID WHERE  LocationID in $entry  GROUP BY LocationID, Attribute ORDER BY SequenceID
        """
    else
        x=
        """
        WITH ledger_subset (ID,SequenceID,Time)
        AS(
            SELECT ID,SequenceID,Max(Time) FROM Ledger WHERE Time <= $ledger_time AND SequenceID BETWEEN $starting AND $ending GROUP BY SequenceID
            ) 
        SELECT  LedgerID,Max(SequenceID),LocationID,Attribute,Value,Unit FROM EnvironmentAttributes INNER JOIN ledger_subset ON EnvironmentAttributes.LedgerID = ledger_subset.ID WHERE  LocationID in $entry  GROUP BY LocationID, Attribute ORDER BY SequenceID
        """
    end
    return query_db(x)
end 
