### Functions that query the database and return information go here ####
"""
    get_last_ledger_id(time::DateTime=Dates.now())

Return the most recent ledger id entry at or before a certain time 
"""
function get_last_ledger_id(time::DateTime=Dates.now())
    ledger_time = db_time(time)
    x = "SELECT Max(ID) FROM Ledger WHERE TIME <= $ledger_time"
    current_id = query_db(x)
    return current_id[1,1]
end 

function get_last_sequence_id(time::DateTime=Dates.now())
    ledger_time = db_time(time)
    x= "SELECT Max(SequenceID) FROM Ledger WHERE Time <= $ledger_time "
    current_id = query_db(x)
    return current_id[1,1]
end 
#=
function get_component(id::Integer)
    comp=query_db("SELECT * FROM Components WHERE ID=$id")
    if nrow(comp)==0
        error("No component with id #$id found")
    end 
    type=comp[1,"Type"]
    if type == "Chemical"
        return get_chemical(id)
    elseif type == "Strain"
        return get_strain(id)
    else
        error("invalid component type for component id #$id")
    end 
end 

function get_chemical(id::Integer)
    chems=query_db("SELECT * FROM Chemicals WHERE ComponentID = $id")
    if nrow(chems)==0
        error("No chemical with component id #$id found.")
    end 
    chem=chems[1,:]
    type=eval(Symbol(chem["Type"]))
    return type(chem["Name"],chem["Molecular_Weight"]*u"g/mol",chem["Density"]*u"g/ml",chem["pubchemid"])
end 

function get_strain(id::Integer)
    strs=query_db("SELECT * FROM Strains WHERE ComponentID")
    if nrow(strs)==0
        error("No strain with component id #$id found.")
    end 
    str=strs[1,:]
    return Strain(str["Genus"],str["Species"],str["Strain"])
end 



""" 
    is_barcode_assignable(Barcode::AbstractString)

check whether `barcode` has an assigned locationID or not.
"""
function is_barcode_assignable(Barcode::AbstractString)
    is_assignable=nrow(query_db("SELECT * FROM Barcodes WHERE Barcode = '$Barcode' AND LocationID IS NULL";returnDataFrame=true)) ==1

    return is_assignable
end  




"""
    well_id(location_id::Integer,well_idx::Integer)

get the WellID for a `location_id` and `well_index`
"""
function well_id(location_id::Integer,well_idx::Integer) 
    out=query_db("SELECT ID From Wells WHERE LocationID= $location_id AND Well_Index=$well_idx";returnDataFrame=true) 
    return out.ID[1] 
end 


""" 
    is_constrained(location)

Check whether a particular location type is constrained. Also compatible with unique location IDs (which map to a location type)
"""
function is_constrained(location_type::AbstractString)
    out=query_db("SELECT IsConstrained FROM LocationTypes WHERE Name = '$location_type'";returnDataFrame=true)
    nrow(out)== 0 ? throw(error("No location type named $location_type found in the database")) : nothing 
    return Bool(out[1,1])
end 

function is_constrained(location_id::Integer)
    return is_constrained(location_type(location_id))
end 

function is_constrained(location_id::Missing)
    return false
end 



"""
    location_type(location_id::Integer)

Return the location type of a given `location_id`.
"""
function location_type(location_id::Integer)
    out=query_db("SELECT Type FROM Locations WHERE ID=$location_id";returnDataFrame=true)
    nrow(out)== 0 ? throw(error("No location ID matching $location_id found in the database")) : nothing 
    return out[1,1]
end 



"""
    is_enforced(encumbrance_id::Integer,ledger_id=get_last_ledger_id())

Check whether an encumbrance is enforced at the time of a given ledger entry.

"""
function is_enforced(encumbrance_id::Integer,ledger_id=get_last_ledger_id())
    x=
    """
    SELECT IsEnforced
    FROM (SELECT Max(ID),EncumbranceID,IsEnforced FROM EncumbranceEnforcement GROUP BY EncumbranceID)
    WHERE EncumbranceID= '$encumbrance_id' AND LedgerID <= $ledger_id
    """
    xout=query_db(x)
    if length(xout)==0
        return false 
    else 
        enforcement=xout[1]["IsEnforced"]
        return Bool(enforcement)
    end  
end 


"""
    location_address(location_id::Integer,ledger_id=get_last_ledger_id())

Return the full address of a `location_id` at any particular `ledger_id` time. (the address is the heirarchical chain of location ids that contain `location_id`). 
"""
function location_address(location_id::Integer,ledger_id=get_last_ledger_id())
    x="""
    WITH RECURSIVE x (tree,idtree,Parent,depth) 
    AS(
         SELECT cast(Name as varchar(100)),cast(Child as varchar(100)), Parent,0
            FROM (SELECT Max(ID),LedgerID,Child,Parent FROM Movements GROUP BY Child) lm INNER JOIN Locations ON lm.Child = Locations.ID
            WHERE Child = $location_id AND LedgerID <= $ledger_id
        UNION ALL
        SELECT cast(concat(Name,',',x.tree) as varchar(100)), cast(concat(e.Child, ',',x.idtree) as varchar(100)), e.Parent,x.depth+1
            FROM (SELECT Max(ID),Child,Parent FROM Movements GROUP BY Child) e INNER JOIN Locations ON e.Child =Locations.ID ,x
            WHERE x.Parent = e.Child
        )
    SELECT tree, idtree FROM x ORDER BY depth DESC LIMIT 1
    """
    xout=query_db(x)
    if  length(xout) == 0 
        return string(location_id)
    else 
        out_ids=xout[1]["idtree"]
        return out_ids
    end
end 


"""
    location_contents(location_id::Integer,ledger_id=get_last_ledger_id())

Return the contents of `location_id` at any particular `ledger_id` time.
"""
function location_contents(location_id::Integer,ledger_id=get_last_ledger_id()) 
    x="""
    SELECT Child
    FROM (SELECT Max(ID),LedgerID,Child,Parent FROM Movements GROUP BY Child) lm INNER JOIN Locations ON lm.Child = Locations.ID 
    WHERE Parent = $location_id AND LedgerID <= $ledger_id
     """
    xout=query_db(x)
    return join(map(y->y["Child"],xout),",")
end 

"""
    location_name(location_id::Integer)

Return the human readable name of `location_id`
"""
function location_name(location_id::Integer)
    out=query_db("SELECT Name FROM Locations WHERE ID=$location_id";returnDataFrame=true)
    nrow(out)== 0 ? throw(error("No location ID matching $location_id found in the database")) : nothing 
    return out[1,1]
end

"""
    occupancy(location_id::Integer,ledger_id=get_last_ledger_id())

Return the fractional occupancy of a `location_id` at any particular `ledger_id` time. 

"""
function occupancy(location_id::Integer,ledger_id=get_last_ledger_id())
    type=location_type(location_id)
    occ=0
    if is_constrained(type)
        occ=0
        children=location_contents(location_id,ledger_id)
        children=Meta.parse.(split(children,","))
        for child in children 
            if isnothing(child)
                continue 
            else 

                child_type=location_type(child)
            x="""SELECT Occupancy FROM LocationConstraints WHERE ParentType = '$type' AND ChildType = '$child_type'"""
            xout=query_db(x,returnDataFrame=true)
            nrow(xout)==0 ? throw(error("Constraint for $type - $child_type pair not found")) : nothing 
            occ += Float64(xout[1,1])
            end 
        end 
    end 
    return occ
end


"""
    occupancy_cost(parent_id::Integer,child_id::Integer,ledger_id=get_last_ledger_id())

Return the fractional occupancy cost of adding `child_id` to `parent_id`
"""
function occupancy_cost(parent_id::Integer,child_id::Integer,ledger_id=get_last_ledger_id())
    p_type=location_type(parent_id)
    c_type=location_type(child_id)
    occ=0
    children=location_contents(parent_id,ledger_id)
    if in(string(child_id),split(children,",")) # if the child already occupies the parent, there is no additional cost to 'adding' it again. 
        return occ 
    end 
    if is_constrained(p_type)
        x="""SELECT Occupancy FROM LocationConstraints WHERE ParentType = '$p_type' AND ChildType = '$c_type'"""
        xout=query_db(x,returnDataFrame=true)
        nrow(xout)==0 ? throw(error("Constraint for $p_type -> $c_type pair not found")) : nothing 
        occ += Float64(xout[1,1])   
    end 
    return occ
end


"""
    is_locked(location_id,ledger_id=get_last_ledger_id())

Return whether or not `location_id` is locked inside its current parent.
"""
function is_locked(location_id::Integer,ledger_id=get_last_ledger_id())
    x="""
    SELECT Max(ID),IsLocked
    FROM Movements 
    WHERE Child = $location_id AND LedgerID <= $ledger_id"""
    xout=query_db(x;returnDataFrame=true)
    if ismissing(xout[1,2])
        return false 
    else 
        return Bool(xout[1,2])
    end 
end 

"""
    can_move(parent_id,child_id,ledger_id=get_last_ledger_id();occupancy_tolerance=1e-6)

Return whether or not `child_id` can be moved into `parent_id`
"""    
function can_move(parent_id::Union{Integer,Missing},child_id::Integer,ledger_id=get_last_ledger_id();occupancy_tolerance=1e-6)
    can=true
    if is_locked(child_id,ledger_id)
        println("location $child_id is currently locked")
        return false
    end 
    if is_constrained(parent_id)
        try 
            cost=occupancy_cost(parent_id,child_id)
            children=Meta.parse.(split(location_contents(parent_id,ledger_id),","))
            if in(child_id,children)
                cost=0
            end 
            can=(occupancy(parent_id,ledger_id) + cost) <= 1 + occupancy_tolerance
            if !can
                println("location $parent_id would become overoccupied.")
            end 
        catch e 
            println(e)
            return false
        end 
        
    end 
    return can
end 



"""
    is_active(location_id::Integer,ledger_id=get_last_ledger_id();encumbrances=false)

Return whether or not `location_id` is active at a paticular `ledger_id` time.

"""
function is_active(location_id::Integer,ledger_id=get_last_ledger_id();encumbrances::Bool=false)
    x=
    """
    SELECT IsActive
    FROM (SELECT Max(ID),LedgerID,LocationID,IsActive FROM Activity GROUP BY LocationID)
    WHERE LocationID= '$location_id' AND LedgerID <= '$ledger_id'
    """
    if encumbrances 
        x=
        """
        WITH y (LedgerID,LocationID,IsActive)
        AS(
        SELECT LedgerID, LocationID, IsActive  From Activity a
        UNION ALL
        SELECT m.LedgerID, m.LocationID, m.IsActive FROM (SELECT * FROM EncumberedActivity a INNER JOIN (Select Max(ID), LedgerID, EncumbranceID, IsEnforced FROM EncumbranceEnforcement WHERE LedgerID <= $ledger_id GROUP BY EncumbranceID) e ON a.EncumbranceID =e.EncumbranceID) m  Where IsEnforced=1
        )
        SELECT IsActive
        FROM (SELECT LedgerID,LocationID,IsActive FROM y GROUP BY LocationID)
        WHERE LocationID= '$location_id' AND LedgerID <= '$ledger_id'
        ORDER BY LedgerID
        """
    end 

    xout=query_db(x)
    if length(xout)==0
        return false 
    else 
        activity=xout[end]["IsActive"]
        return Bool(activity)
    end  
end 




""" 
    active_wells(ledgerID::Integer=get_last_ledger_id())

Return all active wells at any particular `ledger_id` time. 
"""
function active_wells(ledgerID::Integer=get_last_ledger_id();encumbrances::Bool=false)
    x=""
    if encumbrances
        x=""" 
        WITH y (LedgerID,WellID,IsActive)
        AS(
        SELECT Max(a.LedgerID),w.ID,IsActive FROM Wells w INNER JOIN Activity a ON a.LocationID = w.LocationID WHERE LedgerID <= $ledgerID GROUP BY a.LocationID
        UNION ALL
        SELECT Max(m.LedgerID), w.ID, m.IsActive FROM Wells w INNER JOIN (SELECT * FROM EncumberedActivity a INNER JOIN (Select Max(ID), LedgerID, EncumbranceID, IsEnforced FROM EncumbranceEnforcement WHERE LedgerID <= $ledgerID AND IsEnforced=1 GROUP BY EncumbranceID) e ON a.EncumbranceID =e.EncumbranceID) m  ON w.LocationID=m.LocationID GROUP BY m.LocationID
        )
        SELECT Max(LedgerID) , WellID
        FROM y 
        WHERE IsActive = 1
        GROUP BY WellID 
        """
        return query_db(x;returnDataFrame=true)[:,:WellID]
    else 
        x="SELECT t.ID FROM (SELECT Max(a.ID),a.LedgerID,w.ID,a.IsActive FROM Wells w INNER JOIN Activity a on a.LocationID = w.LocationID Group BY a.LocationID) t  WHERE t.IsActive=1 And t.LedgerID <=$ledgerID"
        return query_db(x;returnDataFrame=true)[:,:ID]
    end
end





"""
    well_transfers(entry::AbstractString,ledger_id=get_last_ledger_id();encumbrances=false)

Find all transfers involving wells in `entry`, including all predecessor wells up to `ledger_id`

- `entry` is a comma separated concatenated string of well IDs
"""
function well_transfers(entry::AbstractString,ledger_id=get_last_ledger_id();encumbrances=false)  # find all transfers for that well up to a certain ledger id entry 
    x=""
    if encumbrances 
        x= 
        """
        WITH RECURSIVE y (LedgerID,Source,Destination,Quantity,Unit)
        AS(SELECT e.LedgerID, c.Source,c.Destination,c.Quantity,c.Unit
            FROM (Select Max(ID), LedgerID, EncumbranceID, IsEnforced FROM EncumbranceEnforcement WHERE LedgerID <= $ledger_id GROUP BY EncumbranceID)  e INNER JOIN EncumberedTransfers c ON e.EncumbranceID = c.EncumbranceID WHERE IsEnforced = 1
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
        SELECT DISTINCT  * FROM x WHERE LedgerID <= $ledger_id ORDER BY LedgerID
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
        SELECT DISTINCT  * FROM x WHERE LedgerID <= $ledger_id ORDER BY LedgerID
        """

    end 
return query_db(x;returnDataFrame=true)
end 



"""
   source_transfer(entry::AbstractString, ledger_id=get_last_ledger_id())
   
Return all source transfers involving wells in `entry` up to a `ledger_id` time.
"""
function source_transfers(entry::AbstractString, ledger_id=get_last_ledger_id();encumbrances=false) 
    x=""
    if encumbrances 
        x="""
        WITH y (LedgerID,CompositionID,WellID,Quantity,Unit,Price)
        AS(
        SELECT t.LedgerID, s.CompositionID, t.WellID, t.Quantity, t.Unit, t.Price  From SourceTransfers t INNER JOIN Sources s ON t.SourceID=s.ID 
        UNION ALL
        SELECT c.LedgerID, s.CompositionID, c.WellID, c.Quantity,c.Unit, c.PriceEstimate FROM (SELECT * FROM EncumberedSourceTransfers t INNER JOIN (Select Max(ID), LedgerID, EncumbranceID, IsEnforced FROM EncumbranceEnforcement WHERE LedgerID <= $ledger_id GROUP BY EncumbranceID) e ON t.EncumbranceID =e.EncumbranceID) c INNER JOIN Sources s ON c.SourceID = s.ID Where IsEnforced=1
        )
        SELECT * FROM y WHERE WellID in $entry AND LedgerID <= $ledger_id ORDER BY LedgerID"""
    else
        x="""
        SELECT t.LedgerID,s.CompositionID ,t.WellID, t.Quantity, t.Unit, t.Price From SourceTransfers t INNER JOIN Sources s ON t.SourceID=s.ID WHERE WellID in $entry AND t.LedgerID <= $ledger_id ORDER BY t.LedgerID"""
    end 
    return query_db(x;returnDataFrame=true)
end 



function strain_transfers(entry::AbstractString,ledger_id=get_last_ledger_id();encumbrances=true)
    x=""
    if encumbrances
        x="""
        WITH y (LedgerID,StrainID, WellID)
        AS(
        SELECT LedgerID, StrainID, WellID FROM StrainTransfers 
        UNION ALL 
        SELECT LedgerID, StrainID, WellID FROM (SELECT * FROM EncumberedStrainTransfers t INNER JOIN (Select Max(ID), LedgerID, EncumbranceID, IsEnforced FROM EncumbranceEnforcement WHERE LedgerID <= $ledger_id GROUP BY EncumbranceID) e ON t.EncumbranceID =e.EncumbranceID)  Where IsEnforced=1
        )
        SELECT * FROM y WHERE WellID in $entry AND LedgerID <= $ledger_id ORDER BY LedgerID
        """
    else
        x="""SELECT LedgerID,StrainID,WellID FROM StrainTransfers WHERE WellID in $entry AND LedgerID <= $ledger_id ORDER BY LedgerID"""
    end 
    return query_db(x;returnDataFrame=true)
end 



function chemical_concentrations(entry)
    x="""
    SELECT c.CompositionID ,c.ChemicalID,c.Concentration,c.Unit, i.Molar_Mass, i.Density, i.Class FROM CompositionChemicals c INNER JOIN Chemicals i ON c.ChemicalID = i.Name WHERE CompositionID in $entry
    """
    return query_db(x;returnDataFrame=true)
end 


function strains(entry)
    x="""
    SELECT * FROM Strains WHERE Name in $entry
    """
    return query_db(x;returnDataFrame=true)
end 

function well_location(entry) 
    x=
    """
    SELECT w.ID,w.LocationID, w.Well_Index, t.Name,t.WellCapacity,t.Unit,t.WellRows,t.WellCols FROM (Wells w INNER JOIN Locations l ON l.ID = w.LocationID) INNER JOIN LocationTypes t ON t.Name = l.Type WHERE w.ID in $entry 
    """
    return query_db(x;returnDataFrame=true)
end 

=#