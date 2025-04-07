using JLIMS, Test, Unitful, AbstractTrees,UUIDs, SQLite, DataFrames,Dates

file="./test_db.db"
if isfile(file)
    rm(file)
end
create_db(file)
@connect_SQLite file


#### set up a test lab

@chemical Water "water" Liquid 18.015u"g/mol" 1.00u"g/mL" 962
@chemical Glycerol "glycerol" Liquid missing missing missing 
@chemical Paba "4-aminobenzoic acid" Solid 137.14u"g/mol" 1.35u"g/mL" 978 
@chemical IronNitrate "Iron Nitrate" Solid 179.86u"g/mol" missing  9815404
@chemical LB "LB Broth" Solid missing missing missing 

@organism SMU_UA159 "Streptococcus" "mutans" "UA159" 
@organism SSA_SK36 "Streptococcus" "sanguinis" "SK36" 

@attribute Temperature u"°C"
@attribute Pressure u"atm"
@attribute LinearShaking u"Hz"
@attribute Oxygen u"percent"
@attribute Humidity u"percent"


abstract type Plate <: Labware end # Plates are designed on the SLAS Standard. See Dish for other non-SLAS plate types
abstract type Bottle <: Labware end 
    abstract type ReagentBottle <: Bottle end
    abstract type ScrewBottle <: Bottle end 
    abstract type FilterBottle <: Bottle end
abstract type Tube <: Labware end 
    abstract type Conical <: Tube end 
    abstract type MicroTube <: Tube end 
    abstract type CultureTube <: Tube end 
    abstract type CryoTube <: Tube end 
abstract type Dish <: Labware end 
abstract type Reservior <:Labware end 


@location Lab Location false true 
@location Room Location
@location Bench
@location Incubator Location true false 
@location IncubatorShelf Location false true 
@location BioSpa Location true false 
@location BioSpaDrawer Location true true 
@location BioSpaSlot Location true true 
@location AltemisSlot Location true true 

@occupancy_cost BioSpa BioSpaDrawer 1//4
@occupancy_cost BioSpaDrawer BioSpaSlot 1//2
@occupancy_cost BioSpaSlot Plate 1//1 
@occupancy_cost Incubator IncubatorShelf 1//3



@labware WP96 Plate Well{200} (8,12) Thermo 123456
@labware WP384 Plate Well{80} (16,24) Thermo 123457
@labware Bottle1L ScrewBottle Well{1000000} (1,1) Corning 1 
@labware IronNitrateBottle ReagentBottle Well{1000000} (1,1) Sigma 111
@labware LBBottle ReagentBottle Well{1000000} (1,1) Sigma 123 
@labware PabaBottle ReagentBottle Well{50000} (1,1) Sigma 234

@labware AltemisTube Tube Well{1000} (1,1) Altemis 1234 

@occupancy_cost AltemisSlot AltemisTube 1//1 

@labware AltemisBox Plate AltemisSlot (8,12) Altemis 4321 







jensen_lab=generate_location(Lab,"Jensen Lab")  
main_room=generate_location(Room,"Main Room")
culture_room=generate_location(Room,"Culture Room")
robot_room=generate_location(Room,"Robot Room")
incubator1=generate_location(Incubator,"Upper Incubator")
incubator2=generate_location(Incubator,"Lower Incubator")
shelf1=generate_location(IncubatorShelf,"Upper Shelf")
shelf2=generate_location(IncubatorShelf,"Middle Shelf")
shelf3=generate_location(IncubatorShelf,"Lower Shelf")
shelf4=generate_location(IncubatorShelf,"Middle Shelf")
biospa1=generate_location(BioSpa,"Biospa 1")
dr1=generate_location(BioSpaDrawer,"Drawer 1")
dr2=generate_location(BioSpaDrawer,"Drawer 2")
dr3=generate_location(BioSpaDrawer,"Drawer 3")
dr4=generate_location(BioSpaDrawer,"Drawer 4")
l1=generate_location(BioSpaSlot,"Left")
l2=generate_location(BioSpaSlot,"Left")
l3=generate_location(BioSpaSlot,"Left")
l4=generate_location(BioSpaSlot,"Left")
r1=generate_location(BioSpaSlot,"Right")
r2=generate_location(BioSpaSlot,"Right")
r3=generate_location(BioSpaSlot,"Right")
r4=generate_location(BioSpaSlot,"Right")




b1=generate_location(Bottle1L)
b2=generate_location(PabaBottle,"Paba")
plate1=generate_location(WP96)
box1=generate_location(AltemisBox,"Freezer Box 1")


upload(set_attribute!,jensen_lab,Temperature(25u"°C"))
upload(set_attribute!,jensen_lab,Pressure(1u"atm"))
upload(set_attribute!,biospa1,Temperature(37u"°C"))
upload(set_attribute!,incubator1,Temperature(37u"°C"))

cache(jensen_lab)
upload(set_attribute!,jensen_lab,Temperature(missing))

upload(lock!,main_room)
upload(unlock!,main_room)
upload(toggle_lock!,jensen_lab)
upload(toggle_lock!,jensen_lab)

upload(activate!,main_room)
upload(deactivate!,main_room)
upload(toggle_activity!,main_room)


upload(move_into!,jensen_lab,main_room)
upload(move_into!,jensen_lab,culture_room)
upload(move_into!,jensen_lab,robot_room)
upload(move_into!,culture_room,incubator1)
upload(move_into!,culture_room,incubator2)
upload(move_into!,incubator1,shelf1,true)
upload(move_into!,incubator1,shelf2,true)
upload(move_into!,incubator1,shelf3,true)
upload(move_into!,robot_room,biospa1)
upload(move_into!,biospa1,dr1,true)
upload(move_into!,biospa1,dr2,true)
upload(move_into!,biospa1,dr3,true)
upload(move_into!,biospa1,dr4,true)
upload(move_into!,dr1,l1,true)
upload(move_into!,dr1,r1,true)
upload(move_into!,dr2,l2,true)
upload(move_into!,dr2,r2,true)
upload(move_into!,dr3,l3,true)
upload(move_into!,dr3,r3,true)
upload(move_into!,dr4,l4,true)
upload(move_into!,dr4,r4,true)
upload(move_into!,main_room,b1)
upload(move_into!,main_room,b2)
upload(move_into!,main_room,plate1)


upload(set_attribute!,jensen_lab,Temperature(25u"°C"))


w1=children(b1)[1,1]

w2=children(b2)[1,1]

deposit!(w2,50u"g"*Paba, 20)
deposit!(w1,500u"mL"*Water + 2u"g" *IronNitrate,3)
deposit!(w1,Empty()+SMU_UA159,0)
cache(w1)
cache(w2)

upload(transfer!,w2,w1,5u"g")
upload(transfer!,w1,children(plate1)[1,1],100u"µL")


upload_tag("test_comment")

bc=Barcode(string(UUIDs.uuid4()),"lazy_blue_poodle")
upload_barcode(bc)

bc2=Barcode(string(UUIDs.uuid4()),"nasty_green_baboon")
upload_barcode(bc2)

upload(assign_barcode!,bc2,plate1)


exp_id =upload_experiment("test_experiment","Ben")

p_id=upload_protocol(exp_id,"test_protocol")
encumber( p_id , move_into!,shelf1,plate1)

encumber( p_id , move_into!,l1,plate1)
encumber( p_id , move_into!,main_room,plate1)
encumber( p_id , transfer!,w2,w1,20u"g")
encumber( p_id , set_attribute!,jensen_lab,Humidity(43u"percent"))
encumber( p_id , JLIMS.lock!,plate1)
encumber( p_id , JLIMS.unlock!,plate1)
encumber( p_id , toggle_activity!,plate1)
encumber( p_id , toggle_activity!,plate1)
encumber( p_id , set_attribute!,jensen_lab,Humidity(40u"percent"))
encumber( p_id , move_into!,jensen_lab,b1)
encumber_cache(get_last_encumbrance_id(p_id),plate1)

exp_id = upload_experiment("bufanda","Ben")

p_id=upload_protocol(exp_id,"bufandisimo")

encumber( p_id , transfer!,w1,children(plate1)[4,8],100u"µL")
encumber( p_id , move_into!,culture_room,plate1)
JLIMS.upload_encumbrance_completion(1,get_last_ledger_id())

#reconstruct_location(collect(25:30))
#=
@time reconstruct_location(collect(25:30))

@time reconstruct_location(collect(25:30);cache_results=true)

@time reconstruct_location(collect(25:30))
=#