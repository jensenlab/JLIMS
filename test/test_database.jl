using JLIMS, Test, Unitful, AbstractTrees,UUIDs, SQLite, DataFrames

file="./test/test_db.db"
rm(file)
create_db(file)
@connect_SQLite "./test/test_db.db" 


#### set up a test lab

@chemical Water "water" Liquid 962
@chemical Glycerol "glycerol" Liquid
@chemical Paba "4-aminobenzoic acid" Solid 978
@chemical IronNitrate "Iron Nitrate" Solid 9815404
@chemical LB "LB Broth" Solid 

@strain SMU_UA159 Streptococcus mutans UA159 
@strain SSA_SK36 Streptococcus sanguinis SK36 

@attribute Temperature Unitful.Temperature
@attribute Pressure Unitful.Pressure
@attribute LinearShaking Unitful.Frequency
@attribute Oxygen Unitful.DimensionlessQuantity


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


@location Lab false true 
@location Room 
@location Bench
@location Incubator true false 
@location IncubatorShelf false true 
@location BioSpa true false 
@location BioSpaDrawer true true 
@location BioSpaSlot true true 

@occupancy_cost BioSpa BioSpaDrawer 1//4
@occupancy_cost BioSpaDrawer BioSpaSlot 1//2
@occupancy_cost BioSpaSlot Plate 1//1 
@occupancy_cost Incubator IncubatorShelf 1//3


@well Well200µL 200u"µL"
@well Well80µL 80u"µL"
@well Well1L 1u"L"
@well Well10mL  10u"mL"
@well Well50mL 50u"mL"

@labware WP96 Plate Well200µL (8,12) Thermo 123456
@labware WP384 Plate Well80µL (16,24) Thermo 123457
@labware Bottle1L ScrewBottle Well1L (1,1) Corning 1 
@labware IronNitrateBottle ReagentBottle Well1L (1,1) Sigma 111
@labware LBBottle ReagentBottle Well1L (1,1) Sigma 123 
@labware PabaBottle ReagentBottle Well50mL (1,1) Sigma 234






jensen_lab=generate_location(Lab,"Jensen Lab")  
main_room=generate_location(Room,"Main Room")

#=
culture_room=Room(3,"Culture Room")
robot_room=Room(4,"Robot Room")
incubator1=Incubator(5,"Incubator 1")
incubator2=Incubator(6,"Incubator 2")
shelf1=IncubatorShelf(7,"Upper Shelf")
shelf2=IncubatorShelf(8,"Middle Shelf")
shelf3=IncubatorShelf(9,"Lower Shelf")
shelf4=IncubatorShelf(10,"Middle Shelf")
biospa1=BioSpa(11,"Biospa 1")
dr1=BioSpaDrawer(12,"Drawer 1")
dr2=BioSpaDrawer(13,"Drawer 2")
dr3=BioSpaDrawer(14,"Drawer 3")
dr4=BioSpaDrawer(15,"Drawer 4")
l1=BioSpaSlot(16,"Left")
l2=BioSpaSlot(17,"Left")
l3=BioSpaSlot(18,"Left")
l4=BioSpaSlot(19,"Left")
r1=BioSpaSlot(20,"Right")
r2=BioSpaSlot(21,"Right")
r3=BioSpaSlot(23,"Right")
r4=BioSpaSlot(24,"Right")
=#
b1=generate_location(Bottle1L)
b2=generate_location(PabaBottle,"Paba")
plate1=generate_location(WP96)

#=
set_attribute!(jensen_lab,Temperature(25u"°C"))
set_attribute!(jensen_lab,Pressure(1u"atm"))
set_attribute!(biospa1,Temperature(37u"°C"))
set_attribute!(incubator1,Temperature(37u"°C"))


move_into!(jensen_lab,main_room)
move_into!(jensen_lab,culture_room)
move_into!(jensen_lab,robot_room)
move_into!(culture_room,incubator1)
move_into!(culture_room,incubator2)
move_into!(incubator1,shelf1,true)
move_into!(incubator1,shelf2,true)
move_into!(incubator1,shelf3,true)
move_into!(robot_room,biospa1)
move_into!(biospa1,dr1,true)
move_into!(biospa1,dr2,true)
move_into!(biospa1,dr3,true)
move_into!(biospa1,dr4,true)
move_into!(dr1,l1,true)
move_into!(dr1,r1,true)
move_into!(dr2,l2,true)
move_into!(dr2,r2,true)
move_into!(dr3,l3,true)
move_into!(dr3,r3,true)
move_into!(dr4,l4,true)
move_into!(dr4,r4,true)
move_into!(main_room,b1)
move_into!(main_room,b2)
move_into!(main_room,plate1)
