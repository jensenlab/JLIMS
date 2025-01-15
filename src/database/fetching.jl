

#=
macro get_location(id_expr) 
    q_id=eval(id_expr)
    loc_info=query_db("SELECT * FROM Locations WHERE ID =$q_id")
    if nrow(loc_info) == 0 
        error("location id not found")
    end 
    out=loc_info[1,:]
    typ=Symbol(out["Type"])
    n=string(out["Name"])
    return esc(quote 

    $typ($id_expr,$n)
end)
end 
=#









 


