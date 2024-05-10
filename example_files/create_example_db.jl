using JLIMS,SQLite

file="/Users/BDavid/Desktop/example_db.db"

create_db(file)

db=SQLite.DB(file)

ingredients=parse_ingredient_csv("/Users/BDavid/Documents/GitHub/JLIMS/test/test_ingredients.csv")
primary_comp=parse_composition_csv("/Users/BDavid/Documents/GitHub/JLIMS/test/test_primary_solutions.csv",ingredients)
sec_comp=parse_composition_csv("/Users/BDavid/Documents/GitHub/JLIMS/test/test_solutions.csv",ingredients)
containers=parse_container_csv("/Users/BDavid/Documents/GitHub/JLIMS/test/test_containers.csv")


upload_db.((db,),ingredients)
upload_db.((db,),primary_comp)
upload_db.((db,),sec_comp)
upload_db.((db,),containers)