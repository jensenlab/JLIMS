using JLIMS,SQLite, Dates, Unitful

file="./example_files/example_db.db"

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




s1=Stock(named_id("glucose_25x"),sec_comp[findfirst(x->x.name=="glucose_25x",sec_comp)],50u"ml",Labware(id(),containers[findfirst(x->x.name=="conical_50ml",containers)],"mini-fridge",today()),1,false)

s2=Stock(named_id("water"),primary_comp[findfirst(x->x.name=="water",primary_comp)],50u"ml",Labware(id(),containers[findfirst(x->x.name=="conical_50ml",containers)],"mini-fridge",today()),1,false)

s3=Stock(named_id("vitamin_b12"),primary_comp[findfirst(x->x.name=="vitamin_b12",primary_comp)],5u"g",Labware(id(),containers[findfirst(x->x.name=="vitamin_b12",containers)],"fridge",today()),1,true)

s4=Stock(named_id("alanine"),primary_comp[findfirst(x->x.name=="alanine",primary_comp)],250u"g",Labware(id(),containers[findfirst(x->x.name=="dl_alanine",containers)],"chemical shelf",today()),1,true)

s5=Stock(named_id("iron_nitrate"),primary_comp[findfirst(x->x.name=="iron_nitrate",primary_comp)],2500u"g",Labware(id(),containers[findfirst(x->x.name=="iron_nitrate",containers)],"chemical shelf",today()),1,true)
s6=Stock(named_id("glucose"),primary_comp[findfirst(x->x.name=="glucose",primary_comp)],783u"g",Labware(id(),containers[findfirst(x->x.name=="d_glucose",containers)],"chemical shelf",today()),1,true)
s7=Stock(named_id("ethanol"),primary_comp[findfirst(x->x.name=="ethanol",primary_comp)],500u"ml",Labware(id(),containers[findfirst(x->x.name=="ethanol",containers)],"flammables",today()),1,true)
s8=Stock(named_id("iron_nitrate"),primary_comp[findfirst(x->x.name=="iron_nitrate",primary_comp)],3u"g",Labware(id(),containers[findfirst(x->x.name=="iron_nitrate",containers)],"chemical shelf",today()),1,true)
s9=Stock(named_id("niacinamide"),primary_comp[findfirst(x->x.name=="niacinamide",primary_comp)],2.5u"g",Labware(id(),containers[findfirst(x->x.name=="niacinamide",containers)],"-20C freezer",today()),1,true)

stocks=[s1,s2,s3,s4,s5,s6,s7,s8,s9]

upload_db.((db,),stocks;isactive=true)
s10=Stock(named_id("niacinamide"),primary_comp[findfirst(x->x.name=="niacinamide",primary_comp)],0u"g",Labware(id(),containers[findfirst(x->x.name=="niacinamide",containers)],"-20C freezer",today()-Day(2)),1,true)
upload_db(db,s10)

