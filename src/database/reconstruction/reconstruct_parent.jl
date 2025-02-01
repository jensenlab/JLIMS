function reconstruct_parent(location_ids::Vector{<:Integer},sequence_id::Integer=get_last_sequence_id(),time::DateTime=Dates.now();encumbrances=false)
    all_locs=deepcopy(location_reconstruction_df) # constant defined in reconstruction_utils.jl Columns are location id, sequence id, location
    cache_feet=[]
    for loc_id in location_ids
        n,t=get_location_info(loc_id) 
        loc=t(loc_id,n) 
        parent_ref,cache_foot = fetch_parent_cache(loc_id,0,sequence_id,time;encumbrances=encumbrances)
        loc.parent=parent_ref

        push!(all_locs,(JLIMS.location_id(loc),cache_foot,loc))
        push!(cache_feet,cache_foot)


    end 
    foot = min(minimum(cache_feet),sequence_id)
    mvts=get_movements_as_child(location_ids,foot,sequence_id,time;encumbrances=encumbrances)
    for row in eachrow(mvts) 
        loc_id=row.Child 
        loc=find_most_recent_location(all_locs,loc_id)
        n,t=get_location_info(row.Parent)

        loc.parent=LocationRef(row.Parent,n,t)
        push!(all_locs,(loc_id,row.SequenceID,loc))
    end

    out_locs=find_most_recent_location.((all_locs,),location_ids,(sequence_id,))

    return out_locs 

end 

function reconstruct_parent(location_id::Integer,sequence_id::Integer=get_last_sequence_id(),time::DateTime=Dates.now();encumbrances=false)
    return reconstruct_parent([location_id],sequence_id,time;encumbrances=encumbrances)[1]
end

function fetch_parent_cache(location_id::Integer,starting::Integer=0,ending::Integer=get_last_sequence_id(),time::DateTime=Dates.now();encumbrances=false)

    caches=get_parent_caches(location_id,starting,ending,time;encumbrances=encumbrances)
    p=nothing
    foot=0
    encumber_offset=0 
    if nrow(caches)>0 

        last=caches[end,:]
        if !ismissing(last.ParentID)

            n,t=get_location_info(last.ParentID)
            p=LocationRef(last.ParentID,n,t)
        else
            foot=last.SequenceID
        end
    else
        return nothing,0
    end
    return p,foot
end 



function get_parent_caches(location_id::Integer,starting::Integer=0,ending::Integer=get_last_sequence_id(),time::DateTime=Dates.now();encumbrances=false)

    ledger_time=db_time(time)
    if encumbrances
        return query_db("
        WITH ledger_subset (ID,SequenceID,Time)
        AS(
            SELECT ID,SequenceID,Max(Time) FROM Ledger WHERE Time <= $ledger_time AND SequenceID BETWEEN $starting AND $ending GROUP BY SequenceID
            ),

                    encumbrance_subset (EncumbranceID)
        AS(SELECT e.ID
            FROM (Select ProtocolID, Max(SequenceID), LedgerID, IsEnforced FROM ProtocolEnforcement INNER JOIN ledger_subset ON ProtocolEnforcement.LedgerID = ledger_subset.ID  GROUP BY ProtocolID)  p INNER JOIN Encumbrances e on e.ProtocolID = p.ProtocolID  WHERE IsEnforced = 1

        ),
        
            y (LedgerID,SequenceID,EncumbranceID,LocationID,ParentID)
        AS(SELECT 0,$(get_last_sequence_id())+e.EncumbranceID,e.EncumbranceID, v.LocationID,v.ParentID
            FROM encumbrance_subset e INNER JOIN EncumberedCachedAncestors v ON e.EncumbranceID = v.EncumbranceID 
        UNION ALL 
            SELECT Max(c.LedgerID),l.SequenceID,0, c.LocationID,c.ParentID
            FROM CachedAncestors c INNER JOIN ledger_subset l ON c.LedgerID = l.ID Group By l.SequenceID) 
            SELECT * FROM y WHERE LocationID=$location_id ORDER BY EncumbranceID,SequenceID ")
    else
        return query_db("
            WITH ledger_subset (ID,SequenceID,Time)
        AS(
            SELECT ID,SequenceID,Max(Time) FROM Ledger WHERE Time <= $ledger_time AND SequenceID BETWEEN $starting AND $ending GROUP BY SequenceID 
            ) ,
        y (LedgerID,SequenceID,EncumbranceID, LocationID, ParentID)
        AS( SELECT Max(c.LedgerID),l.SequenceID,0, c.LocationID,c.ParentID FROM CachedAncestors c INNER JOIN ledger_subset l ON c.LedgerID = l.ID WHERE c.LocationID =$location_id Group By SequenceID ORDER BY SequenceID ) 
        SELECT * from y
        " )
        
    end
end


function get_movements_as_child(locs::Vector{<:Integer},starting::Integer=0,ending::Integer=get_last_sequence_id(),time::DateTime=Dates.now();encumbrances=false)
    entry=query_join_vector(locs)
    ledger_time=db_time(time)
    x=""
    if encumbrances 
        x=
        """
            WITH ledger_subset (ID,SequenceID,Time)
        AS(
            SELECT ID,SequenceID,Max(Time) FROM Ledger WHERE Time <= $ledger_time AND SequenceID BETWEEN $starting AND $ending GROUP BY SequenceID
            ) ,

                    encumbrance_subset (EncumbranceID)
        AS(SELECT e.ID
            FROM (Select ProtocolID, Max(SequenceID), LedgerID, IsEnforced FROM ProtocolEnforcement INNER JOIN ledger_subset ON ProtocolEnforcement.LedgerID = ledger_subset.ID  GROUP BY ProtocolID)  p INNER JOIN Encumbrances e on e.ProtocolID = p.ProtocolID  WHERE IsEnforced = 1

        ),
         y (LedgerID,SequenceID,EncumbranceID, Parent,Child)
        AS(SELECT 0,$(get_last_sequence_id())+v.EncumbranceID, v.EncumbranceID, v.Parent,v.Child
            FROM encumbrance_subset e INNER JOIN EncumberedMovements v ON e.EncumbranceID = v.EncumbranceID
        UNION ALL 
            SELECT c.LedgerID,l.SequenceID,0, c.Parent,c.Child
            FROM Movements c INNER JOIN ledger_subset l ON c.LedgerID = l.ID) ,
        z( LedgerID, SequenceID,EncumbranceID,Parent,Child) 
        As(SELECT  LedgerID,Max(SequenceID),EncumbranceID, Parent,Child FROM y WHERE  Child in $entry GROUP BY Child  ORDER BY   SequenceID 
        )
        SELECT * FROM z 
        """
    else
        x=
        """
            WITH ledger_subset (ID,SequenceID,Time)
        AS(
            SELECT ID,SequenceID,Max(Time) FROM Ledger WHERE Time <= $ledger_time AND SequenceID BETWEEN $starting AND $ending GROUP BY SequenceID
            ) ,
             y(LedgerID, SequenceID,EncumbranceID,Parent,Child) 
             AS( 
             SELECT  LedgerID,Max(SequenceID),0,Parent,Child FROM Movements INNER JOIN ledger_subset ON Movements.LedgerID = ledger_subset.ID WHERE  Child in $entry GROUP BY Child   ORDER BY SequenceID 
             )
        Select * FROM y 
        """
    end
    return query_db(x)
end 
