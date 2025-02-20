"""
    append_ledger()
Add an entry to the end of ledger and return the ID of that entry.
"""
function append_ledger() 
    seq_id=get_last_sequence_id()+1
    return update_ledger(seq_id)
end 



"""
    insert_ledger()

Increase the **SequenceID** value for all ledger entries whose **SequenceID** Value is greater than or equal to `sequence_id`, then insert a ledger new entry into the sequence at `sequence_id`
"""
function insert_ledger(sequence_id::Integer)
    execute_db("""
    UPDATE Ledger SET SequenceID = SequenceID +1 WHERE SequenceID >= $sequence_id
    """)
    return update_ledger(sequence_id)
end 





function update_ledger(sequenceID::Integer)
    time=db_time(Dates.now())
    execute_db("""
    INSERT OR IGNORE INTO Ledger(SequenceID,Time)
    Values($sequenceID,$time)   
    """)
    out=query_db("SELECT Max(ID) FROM Ledger")[1,:]
    return out["Max(ID)"]
end 





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

function get_last_ledger_id(sequence_id::Integer,time::DateTime=Dates.now())
    ledger_time=db_time(time)
    x="SELECT Max(ID) FROM LEDGER WHERE SequenceID = $sequence_id AND TIME <= $ledger_time"
    current_id=query_db(x)
    return current_id[1,1]
end 

function get_last_sequence_id(time::DateTime=Dates.now())
    ledger_time = db_time(time)
    x= "SELECT Max(SequenceID) FROM Ledger WHERE Time <= $ledger_time "
    current_id = query_db(x)
    return current_id[1,1]
end 


function get_sequence_id(ledger_id::Integer) 
    x="SELECT SequenceID FROM Ledger WHERE Id = $ledger_id"
    return query_db(x)[1,1]
end 


function get_all_ledger_ids(sequence_id::Integer,time::DateTime=Dates.now())
    ledger_time=db_time(time)
    x="SELECT ID FROM LEDGER WHERE SequenceID = $sequence_id AND TIME <= $ledger_time"
    current_id=query_db(x)
    return current_id[:,"ID"]
end 


function get_ledger_time(ledger_Id::Integer)
    x="SELECT Time FROM Ledger WHERE ID=$ledger_id"
    return julia_time(query_db(x)[1,1])
end








function isa_transfer(ledger_id::Integer)

    x=" SELECT  LedgerID FROM Transfers WHERE LedgerID = $ledger_id"
    out=query_db(x)
    if nrow(out) == 1 
        return true 
    else 
        return false
    end
end 


function isa_movement(ledger_id::Integer)
    x=" SELECT LedgerID FROM Movements WHERE LedgerID = $ledger_id"
    out=query_db(x)
    if nrow(out) == 1 
        return true 
    else 
        return false
    end
end 

function isa_environment_attribute(ledger_id::Integer)
    x= "SELECT LedgerID FROM EnvironmentAttributes WHERE LedgerID = $ledger_id"
    out=query_db(x)
    if nrow(out) == 1 
        return true 
    else 
        return false
    end
end 


function isa_lock(ledger_id::Integer)
    x= "SELECT LedgerID FROM Locks WHERE LedgerID = $ledger_id"
    out=query_db(x)
    if nrow(out) == 1 
        return true 
    else 
        return false
    end
end 

function isa_activity(ledger_id::Integer)
    x= "SELECT LedgerID FROM Activity WHERE LedgerID = $ledger_id"
    out=query_db(x)
    if nrow(out) == 1 
        return true 
    else 
        return false
    end
end 