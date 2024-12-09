using JLIMS, Test, Unitful, AbstractTrees,UUIDs

#### import a proxy database of lab objects

@chemical Water "water" Liquid 962
@chemical Glycerol "glycerol" Liquid
@chemical Paba "4-aminobenzoic acid" Solid 978
@chemical IronNitrate "Iron Nitrate" Solid 9815404
@chemical LB "LB Broth" Solid 

@strain SMU_UA159 Streptococcus mutans UA159 
@strain SSA_SK36 Streptococcus sanguinis SK36 

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


jensen_lab=Lab(1,"Jensen Lab")
main_room=Room(2,"Main Room")
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
current_idx=25
b1=generate_labware(Bottle1L, current_idx)
b2=generate_labware(PabaBottle, current_idx+2)
plate1=generate_labware(WP96, current_idx+4)



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




# test new unit parsing 
@testset "NewUnitParsing" begin
    @test uparse("OD",unit_context=[Unitful,JensenLabUnits])==u"OD"
    @test uparse("RFU",unit_context=[Unitful,JensenLabUnits])==u"RFU"
    @test uparse("X",unit_context=[Unitful,JensenLabUnits])==u"X"
end 

@testset "ChemicalTypes" begin 
    @test Paba isa Solid
    @test Water isa Liquid
end 





a=100u"mL"*Water #solution
b=10u"g"*Paba # mixture
c=5u"g"*IronNitrate #mixture
d=10u"mL"*Glycerol #solution
e=Empty()+SMU_UA159


@testset "Stocks" begin
    @test a isa Solution 
    @test b isa Mixture 
    @test e isa Culture
    @test volume_estimate(b) == quantity(b)/density(Paba) # volume estimate method
    @test 1u"mol"*Paba == convert(u"g",1u"mol",Paba)*Paba # equivalence of the mass vs mol constructors 
    @test 0.01u"kg"*Paba == b # equivalence of unit changes 
end 


@testset "MixingArithmetic" begin 
    @test c+b isa Mixture 
    @test a+c isa Solution 
    @test a+e isa Culture
    @test a==a+Empty() #identity  
    @test a-a == Empty() #identity
    @test allequal([a+b+c , b+c+a , c+a+b]) #commutative property
    @test ((a+b)+c)==(a + (b+c)) #associative property
    @test a+b+c+d-(b+d) == a+c # subtraction 
    @test_throws JLIMS.MixingError a-b # removing paba from pure water results in a mixing error ->  violation of non-negativity constraints on masses and volumes
    @test 3*a == a+a+a # scalar multiplication 
    @test a * 3 == 3 * a # scalar multiplication  commutative property
    @test a/3 == 1/3 * a # scalar division 
    @test 3*(a+e) == a+a+a+e+e+e # there is no quantity to track for e in this case, but it does contribute to the organismal contents
    @test e+a-e !=a # identity property does not hold for cultures 
    @test e-e != Empty() # ' ' 
end 

@testset "Locations" begin
    @test jensen_lab isa Lab
    @test occupancy(jensen_lab) == 0//1 
    @test occupancy(biospa1)==1//1 
    @test_throws JLIMS.OccupancyError can_move_into(biospa1,jensen_lab)
    @test_throws JLIMS.LockedLocationError can_move_into(main_room,dr1)
    @test_throws JLIMS.AlreadyLocatedInError can_move_into(jensen_lab,main_room)
end 


w1=Well1L(1,"testwell1",nothing,a)
w2=Well10mL(2,"testwell2",nothing,b)
w3=Well1L(2,"testwell3",nothing,(a/10)+e)

w4,w5=transfer(w2,w3,5u"g")

@testset "Wells" begin
   @test stock(w1)==a 
   @test capacity(w1)==1u"L"
   @test stock(sterilize(w3)) == a/10 # removes the organisms only 
   @test stock(empty(w3))==Empty()
   @test stock(w5) == stock(w3)+stock(w2)/2
   @test_throws MixingError transfer(w2,w1,20u"g") # try to transfer 20 g from a 10 g stock of paba
end 







