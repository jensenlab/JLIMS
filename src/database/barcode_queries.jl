

function get_barcode(barcode::String)

    x="""SELECT Name, LocationID FROM Barcodes WHERE Barcode = '$barcode' LIMIT 1"""

    out=query_db(x)[1,:]

    bc= Barcode(UUIDs.UUID(barcode),out.Name,out.LocationID)

    return bc 
end 

