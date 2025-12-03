using JLIMS, Test, Unitful, AbstractTrees,UUIDs, SQLite, DataFrames,Dates

println("building sample database...")

include("build_test_database.jl")

println("sample database complete.")

println("testing cache repair tools...")

include("test_cache_repair.jl")
println("cache repair complete")
# test new unit parsing 
@testset "NewUnitParsing" begin
    @test uparse("OD",unit_context=[Unitful,JensenLabUnits])==u"OD"
    @test uparse("RFU",unit_context=[Unitful,JensenLabUnits])==u"RFU"
    @test uparse("X",unit_context=[Unitful,JensenLabUnits])==u"X"
end 

x="water"
y="SMU_UA159"
@testset "ChemicalTypes" begin 
    @test chem"paba" isa Solid
    @test chem"water" isa Liquid
    @test chemparse(x,chem_context=[JLIMS,TestChemOrg]) == chem"water"
    @test org"SMU_UA159" isa Organism 
    @test orgparse(y,org_context=[JLIMS,TestChemOrg]) == org"SMU_UA159"
end 





a=100u"mL"*chem"water" #solution
b=10u"g"*chem"paba" # mixture
c=5u"g"*chem"iron_nitrate" #mixture
d=10u"mL"*chem"glycerol" #solution
e=Empty()+org"SMU_UA159"

@testset "Stocks" begin
    @test a isa Solution 
    @test b isa Mixture 
    @test e isa Culture
    @test volume_estimate(b) == quantity(b)/density(chem"paba") # volume estimate method
    @test 1u"mol"*chem"paba" == convert(u"g",1u"mol",chem"paba")*chem"paba" # equivalence of the mass vs mol constructors 
    @test 0.01u"kg"*chem"paba" == b # equivalence of unit changes 
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
    @test in(main_room, jensen_lab) == true 
    @test in(plate1, jensen_lab) == true
    @test JLIMS.softequal(jensen_lab,deepcopy(jensen_lab)) ==true 
    @test JLIMS.softequal(l1,deepcopy(l1)) == true 
end 


w1=Well{1000000}(1,"testwell1",nothing,a)
w2=Well{10000}(2,"testwell2",nothing,b)
w3=Well{1000000}(2,"testwell3",nothing,(a/10)+e)

w4,w5=transfer(w2,w3,5u"g")

@testset "Wells" begin
   @test stock(w1)==a 
   @test JLIMS.wellcapacity(w1)==1u"L"
   @test stock(sterilize(w3)) == a/10 # removes the organisms only 
   @test stock(drain(w3)) == e
   @test stock(empty(w3))==Empty()
   @test stock(empty(w3)) == stock(sterilize(drain(w3))) # empty == dump |> sterilize 
   @test stock(w5) == stock(w3)+stock(w2)/2
   @test_throws MixingError transfer(w2,w1,20u"g") # try to transfer 20 g from a 10 g stock of paba
   @test_throws WellCapacityError Well{10000}(4,"testwell4",nothing,a) # try to put a 100mL stock in a 10 mL well
end 


@testset "Environments" begin 
    @test Temperature(10u"°C") == Temperature(10u"°C")
    @test Temperature(10u"°C") != Temperature(1u"°C")
    @test environment(jensen_lab)==environment(main_room)
    @test environment(biospa1)==environment(dr1)
end 

rm(file)



