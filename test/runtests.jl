using JLIMS, Test, Unitful

#### import a proxy database of lab objects 
chemicals=parse_chemical_csv("test_ingredients.csv")
strains=parse_strain_csv("test_strains.csv")
water=chemicals[1]
iron_nitrate=chemicals[2]
magnesium_sulfate=chemicals[4]
SMU_UA159=strains[1]
conical50=Container("conical_50ml",50u"mL",(1,1))
WP96=Container("plate_96",200u"µL",(8,12))


sol1=Solution(Dict(water=>100u"percent"))
mix1=Mixture(Dict(iron_nitrate=>100u"percent"))
sol2=Solution(Dict(water=>100u"percent",iron_nitrate=>3u"g/L"))
cul1=Culture(Dict(water=>100u"percent",SMU_UA159=>0.1u"OD"))
w1=Well(1,"water",1,conical50)
w2=Well(2,"iron nitrate",1,conical50)
w3=Well(3,"test",1,conical50)
w4=Well(4,"plate1",1,WP96)

# test new unit parsing 
@testset "NewUnitParsing" begin
    @test uparse("OD",unit_context=[Unitful,JensenLabUnits])==u"OD"
    @test uparse("RFU",unit_context=[Unitful,JensenLabUnits])==u"RFU"
    @test uparse("X",unit_context=[Unitful,JensenLabUnits])==u"X"
end 

@testset "IngredientTypes" begin 
    @test Solid <: Chemical 
    @test Liquid <: Chemical
    @test Chemical <: Ingredient
    @test Organism <: Ingredient
    @test water isa Liquid
    @test iron_nitrate isa Solid 
    @test SMU_UA159 isa Organism 
end 



#test stock math 
@testset "StockMath" begin 
    s1= Stock(sol1,50u"ml",w1)
    s2=Stock(mix1,20u"g",w2)
    s3=Stock(cul1,40u"ml",w3)
    s2,s4=transfer(s2,s1,10u"g")
    e=nothing
    try Stock(sol1,51u"mL",w1) catch e end 
    @test e isa CapacityError
    @test typeof(s1)==LiquidStock
    @test typeof(s2)==SolidStock
    @test typeof(s3)==CultureStock
    @test s4.quantity==50u"ml"
    @test s4.composition.ingredients[iron_nitrate]==200u"g/l"
    @test (s4.well)==(s1.well)
    @test s2.quantity==10u"g"
    s7,s5=transfer(s4,s3,3u"ml")
    @test s5.composition.ingredients[iron_nitrate]<s7.composition.ingredients[iron_nitrate] # concentration of iron nitrate should be less than the stock
    @test s5.quantity==43u"ml"
    @test typeof(s5) ==CultureStock
end 





