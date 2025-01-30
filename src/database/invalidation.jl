function operation_touches(ledger_id::Integer)

end 



function transfer_touches(ledger_id::Integer)

    x=" SELECT  Source, Destination FROM Transfers WHERE LedgerID = $ledger_id"
    out=query_db(x)[1,:]
    return out["Source"],out["Destination"]
end 


function movement_touches(ledger_id::Integer)
    x=" SELECT Parent, Child FROM Movements WHERE LedgerID = $ledger_id"

    out=query_db(x)[1,:]
    return out["Parent"],out["Child"]
end 

function environment_touches(ledger_id::Integer)
    x= "SELECT LocationID FROM EnvironmentAttributes WHERE LedgerID = $ledger_id"
    out=query_db(x)[1,:]
    return out["LocationID"]
end 



