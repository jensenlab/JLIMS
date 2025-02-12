








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



