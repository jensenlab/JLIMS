macro connect_SQLite(DB_PATH)
    return esc(quote
        import JLIMS: execute_db,query_db,get_location_info,get_attribute,sql_transaction
        const db=SQLite.DB($DB_PATH)
        function execute_db(query::String)
            
            DBInterface.execute(db, "PRAGMA foreign_keys = ON;") # when you open a connection, it defaults to turning foreign key constraints off.
            SQLite.execute(db, query)
            #=
            try
                SQLite.execute(db, query)
                
            catch e
                println("Error executing query: ", e)
            finally
                SQLite.close(db)
            end
            =#
            
        end
        function query_db(query::String)
            #db = SQLite.DB($DB_PATH)
            DBInterface.execute(db, "PRAGMA foreign_keys = ON;") # when you open a connection, it defaults to turning foreign key constraints off.
            results = DataFrame(DBInterface.execute(db, query))
            #SQLite.close(db)
            return results
        end

        function sql_transaction(f::Function)
            #db=SQLite.DB($DB_PATH)
            SQLite.transaction(f,db)
        end

        function sql_commit(name::String)
            #db=SQLite.DB($DB_PATH)
            SQLite.commit(db,name)
        end

        function sql_rollback(name::String)
            #db=SQLite.DB($DB_PATH)
            SQLite.rollback(db,name)
        end 

        function get_location_info(id::Integer)
            loc_info=query_db("SELECT * FROM Locations WHERE ID =$id")
            if nrow(loc_info) == 0 
                error("location id not found")
            end 
            out=loc_info[1,:]
            return string(out["Name"]), eval(Meta.parse(out["Type"]))
        end 

        function get_attribute(attr::String)
            return eval(Meta.parse(attr))
        end
    end )

end 

function execute_db(query::String)
    return error("use @connect_SQLite to connect to a database")
end 

function query_db(query::String)
    return error("use @connect_SQLite to connect to a database")
end 

function sql_transaction(f::Function)
    return error("use @connect_SQLite to connect to a database")
end 
function sql_commit(name::String)
    return error("use @connect_SQLite to connect to a database")
end 
function sql_rollback(name::String)
    return error("use @connect_SQLite to connect to a database")
end 



function query_join_vector(entry::Vector{<:Number})
    return string("(",join(entry,","),")")
end 

function query_join_vector(entry::Vector{String})
    return string("('",join(entry,"','"),"')")
end 


function db_time(time::Dates.DateTime)
    return Dates.datetime2unix(time)
end 


function julia_time(time::Float64)
    return Dates.unix2datetime(time)
end 

function get_all_attributes()
    x="SELECT * FROM Attributes"
    return query_db(x)
end 