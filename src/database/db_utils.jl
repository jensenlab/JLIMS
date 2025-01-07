macro connect_SQLite(DB_PATH)
    return esc(quote
        function execute_db(query::String)
            db=SQLite.DB($DB_PATH)
            DBInterface.execute(db, "PRAGMA foreign_keys = ON;") # when you open a connection, it defaults to turning foreign key constraints off.
            try
                SQLite.execute(db, query)
                
            catch e
                println("Error executing query: ", e)
            finally
                SQLite.close(db)
            end
        end
        function query_db(query::String)
            db = SQLite.DB($DB_PATH)
            DBInterface.execute(db, "PRAGMA foreign_keys = ON;") # when you open a connection, it defaults to turning foreign key constraints off.
            results = DataFrame(DBInterface.execute(db, query))
            SQLite.close(db)
            return results
        end
    end )

end 



function query_join_vector(entry::Vector{Number})
    return string("(",join(entry,","),")")
end 

function query_join_vector(entry::Vector{String})
    return string("('",join(entry,"','"),"')")
end 



        
