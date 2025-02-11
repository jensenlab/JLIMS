using JLIMS, Test, Unitful, AbstractTrees,UUIDs, SQLite, DataFrames,Dates

println("building sample database...")

include("build_test_database.jl")

println("sample database complete.")


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
   @test stock(drain(w3)) == e
   @test stock(empty(w3))==Empty()
   @test stock(empty(w3)) == stock(sterilize(drain(w3))) # empty == dump |> sterilize 
   @test stock(w5) == stock(w3)+stock(w2)/2
   @test_throws MixingError transfer(w2,w1,20u"g") # try to transfer 20 g from a 10 g stock of paba
   @test_throws WellCapacityError Well10mL(4,"testwell4",nothing,a) # try to put a 100mL stock in a 10 mL well
end 


@testset "Environments" begin 
    @test Temperature(10u"°C") == Temperature(10u"°C")
    @test Temperature(10u"°C") != Temperature(1u"°C")
    @test environment(jensen_lab)==environment(main_room)
    @test environment(biospa1)==environment(dr1)
end 

rm(file)



