function reconstruct_parents(location_ids::Vector{<:Integer},sequence_id::Integer=get_last_sequence_id(),time::DateTime=Dates.now();encumbrances=false)
    mvmts=get_movements_as_child(location_ids)

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
        AS(SELECT 0,0,e.EncumbranceID, v.LocationID,v.ParentID
            FROM encumbrance_subset e INNER JOIN EncumberedCachedParents v ON e.EncumbranceID = v.EncumbranceID 
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
        AS(SELECT 0,0, v.EncumbranceID, v.Parent,v.Child
            FROM encumbrance_subset e INNER JOIN EncumberedMovements v ON e.EncumbranceID = v.EncumbranceID
        UNION ALL 
            SELECT c.LedgerID,l.SequenceID,0, c.Parent,c.Child
            FROM Movements c INNER JOIN ledger_subset l ON c.LedgerID = l.ID) ,
        z( LedgerID, SequenceID,EncumbranceID,Parent,Child) 
        As(SELECT  LedgerID,Max(SequenceID),Max(EncumbranceID), Parent,Child FROM y WHERE  Child in $entry   ORDER BY  EncumbranceID, SequenceID 
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
