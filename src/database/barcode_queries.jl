

function get_barcode(barcode::String)

    x="""SELECT Name, LocationID FROM Barcodes WHERE Barcode = '$barcode' LIMIT 1"""

    out=query_db(x)[1,:]

    bc= Barcode(UUIDs.UUID(barcode),out.Name,out.LocationID)

    return bc 
end 

function get_all_barcodes(location_id::Integer;return_limit::Integer=3)

    x="""SELECT Barcode,Name FROM Barcodes WHERE LocationID = $location_id LIMIT $return_limit"""
    
    out=query_db(x)
    bcs = Barcode[] 
    for row in eachrow(out) 
        bc = Barcode(UUIDs.UUID(row.Barcode),row.Name,location_id)
        push!(bcs,bc)
    end 
    return bcs 
end 
