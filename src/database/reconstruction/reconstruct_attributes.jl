


function reconstruct_attributes(location_ids::Vector{<:Integer},sequence_id::Integer=get_last_sequence_id(),time::DateTime=Dates.now();encumbrances=false)
        all_locs=Dict{Integer,Location}() # constant defined in reconstruction_utils.jl Columns are location id, sequence id, location
        cache_feet=[]
        for loc_id in location_ids
 
            loc,cache_foot = fetch_attribute_cache(loc_id,0,sequence_id,time;encumbrances=encumbrances)

            all_locs[JLIMS.location_id(loc)]=loc
            push!(cache_feet,cache_foot)
        end 
    
        foot = min(minimum(cache_feet),sequence_id)
        attrs=get_environment_attributes(location_ids,foot,sequence_id,time;encumbrances=encumbrances)
        for row in eachrow(attrs) 
            loc_id=row.LocationID 
            attr=get_attribute(row.Attribute)
            val=row.Value
            un=row.Unit
            set_attribute!(all_locs[loc_id],attr(val*Unitful.uparse(un)))
        end
    
        return map(x->all_locs[x],location_ids)
    
end 

function reconstruct_attributes(location_id::Integer,sequence_id::Integer=get_last_sequence_id(),time::DateTime=Dates.now();encumbrances=false)
    return reconstruct_attributes([location_id],sequence_id,time;encumbrances=encumbrances)[1]
end 


function reconstruct_attributes!(locations::Vector{<:Location},sequence_id::Integer=get_last_sequence_id(),time::DateTime=Dates.now();encumbrances=false)

    parallel_locs=reconstruct_attributes(location_id.(locations),sequence_id,time;encumbrances=encumbrances)
    for i in eachindex(locations)
        locations[i].attributes = JLIMS.attributes(parallel_locs[i])
    end 
    return nothing 
end 

function reconstruct_attributes!(location::Location ,sequence_id::Integer=get_last_sequence_id(),time::DateTime=Dates.now();encumbrances=false)
    parallel_loc=reconstruct_attributes(locaton_id(location),sequence_id,time;encumbrances=encumbrances)
    location.attributes=JLIMS.attributes(parallel_loc)
    return nothing 
end 


function get_attribute(attr::String)
    return eval(Symbol(attr))
end

function fetch_attribute_cache(location_id::Integer,starting::Integer=0,ending::Integer=get_last_sequence_id(),time::DateTime=Dates.now();encumbrances=false)
        caches=get_attribute_caches(location_id,starting,ending,time;encumbrances=encumbrances)
        n,t=get_location_info(location_id)

        loc=t(location_id,n)
        foot=0
        if nrow(caches)>0 
    
            last=caches[end,:]
            attr_id=last["AttributeSetID"]
            attr_set=query_db("SELECT * FROM CachedAttributes WHERE AttributeSetID = $attr_id")
            foot=last["SequenceID"]
            for i in 1:nrow(attr_set)
                attr=get_attribute(attr_set[i,"AttributeID"])
                val=attr_set[i,"Value"]
                un=attr_set[i,"Unit"]
                set_attribute!(loc,attr(val*Unitful.uparse(un)))
            end 
        end 

        return loc, foot

end 




function get_attribute_caches(location_id::Integer,starting::Integer=0,ending::Integer=get_last_sequence_id(),time::DateTime=Dates.now();encumbrances=false)

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
            
                y (LedgerID,SequenceID,EncumbranceID,LocationID,AttributeSetID)
            AS(SELECT 0,$(get_last_sequence_id())+e.EncumbranceID,e.EncumbranceID, v.LocationID,v.AttributeSetID
                FROM encumbrance_subset e INNER JOIN EncumberedCachedEnvironments v ON e.EncumbranceID = v.EncumbranceID 
            UNION ALL 
                SELECT Max(c.LedgerID),l.SequenceID,0, c.LocationID,c.AttributeSetID
                FROM CachedEnvironments c INNER JOIN ledger_subset l ON c.LedgerID = l.ID Group By l.SequenceID) 
                SELECT * FROM y WHERE LocationID=$location_id ORDER BY EncumbranceID,SequenceID ")
        else
            return query_db("
                WITH ledger_subset (ID,SequenceID,Time)
            AS(
                SELECT ID,SequenceID,Max(Time) FROM Ledger WHERE Time <= $ledger_time AND SequenceID BETWEEN $starting AND $ending GROUP BY SequenceID 
                ) ,
            y (LedgerID,SequenceID,EncumbranceID, LocationID, AttributeSetID)
            AS( SELECT Max(c.LedgerID),l.SequenceID,0, c.LocationID,c.AttributeSetID FROM CachedEnvironments c INNER JOIN ledger_subset l ON c.LedgerID = l.ID WHERE c.LocationID =$location_id Group By SequenceID ORDER BY SequenceID ) 
            SELECT * from y
            " )
            
        end
end






function get_environment_attributes(locs::Vector{<:Integer},starting::Integer=0,ending::Integer=get_last_sequence_id(), time::DateTime=Dates.now();encumbrances=false)
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

                    encumbrance_subset (EncumbranceID)
        AS(SELECT e.ID
            FROM (Select ProtocolID, Max(SequenceID), LedgerID, IsEnforced FROM ProtocolEnforcement INNER JOIN ledger_subset ON ProtocolEnforcement.LedgerID = ledger_subset.ID  GROUP BY ProtocolID)  p INNER JOIN Encumbrances e on e.ProtocolID = p.ProtocolID  WHERE IsEnforced = 1

        ),
        
        y (LedgerID,SequenceID, EncumbranceID, LocationID,Attribute,Value,Unit)
        AS(SELECT 0,$(get_last_sequence_id())+e.EncumbranceID,e.EncumbranceID, v.LocationID,v.Attribute,v.Value,v.Unit
            FROM encumbrance_subset  e INNER JOIN EncumberedEnvironments v ON e.EncumbranceID = v.EncumbranceID 
        UNION ALL 
            SELECT c.LedgerID,l.SequenceID,0,c.LocationID,c.Attribute,c.Value,c.Unit
            FROM EnvironmentAttributes c INNER JOIN ledger_subset l on l.ID = c.LedgerID) ,
        
        z (LedgerID,SequenceID,EncumbranceID,LocationID,Attribute,Value,Unit)
        AS(Select LedgerID, Max(SequenceID),EncumbranceID,LocationID,Attribute,Value,Unit FROM y WHERE  LocationID in $entry  GROUP BY LocationID, Attribute ORDER BY SequenceID)
            


        SELECT * FROM z
        """
    else
        x=
        """
                    WITH ledger_subset (ID,SequenceID,Time)
        AS(
            SELECT ID,SequenceID,Max(Time) FROM Ledger WHERE Time <= $ledger_time AND SequenceID BETWEEN $starting AND $ending GROUP BY SequenceID 
            ) ,
        y (LedgerID,SequenceID,EncumbranceID, LocationID, Attribute, Value,Unit)
        AS( SELECT c.LedgerID,l.SequenceID,0, c.LocationID,c.Attribute,c.Value,c.Unit FROM EnvironmentAttributes c INNER JOIN ledger_subset l ON c.LedgerID = l.ID) ,

                z (LedgerID,SequenceID,EncumbranceID,LocationID,Attribute,Value,Unit)
        AS(Select LedgerID, Max(SequenceID),EncumbranceID,LocationID,Attribute,Value,Unit FROM y WHERE  LocationID in $entry  GROUP BY LocationID, Attribute ORDER BY SequenceID)
            


        SELECT * FROM z
        """
    end
    return query_db(x)
end 