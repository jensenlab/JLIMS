using JLIMS, Test, Unitful

#### import a proxy database of lab objects 
ingredient_db=parse_ingredient_csv("test_ingredients.csv")

container_db=parse_container_csv("test_containers.csv")

primary_solution_db=parse_composition_csv("test_primary_solutions.csv",ingredient_db)

solution_db=parse_composition_csv("test_solutions.csv",ingredient_db)

water=primary_solution_db[findfirst(x->x.name=="water",primary_solution_db)]
iron_nitrate=primary_solution_db[findfirst(x->x.name=="iron_nitrate",primary_solution_db)]
cdm_aas=solution_db[findfirst(x->x.name=="cdm_amino_acids_50x",solution_db)]

con50=container_db[findfirst(x->x.name=="conical_50ml",container_db)]
iron_container=container_db[findfirst(x->x.name=="iron (III) nitrate nonohydrate",container_db)]
# test new unit parsing 
@testset "NewUnitParsing" begin
    @test uparse("OD",unit_context=[Unitful,JensenLabUnits])==u"OD"
    @test uparse("RFU",unit_context=[Unitful,JensenLabUnits])==u"RFU"
    @test uparse("X",unit_context=[Unitful,JensenLabUnits])==u"X"
end 


# test labware building 
@testset "LabwareBuilding" begin
    for container in container_db 
        lw =Labware(named_id(container.name),container,1)
        @test lw.id[1:length(container.name)]==container.name
        @test lw.container==container
    end 
end 


#test stock math 
@testset "StockMath" begin 
    s1= Stock(water,50u"ml",Labware(con50,1))
    s2=Stock(iron_nitrate,20u"g",Labware(iron_container,1))
    s3=Stock(cdm_aas,40u"ml",Labware(con50,1))

    s2,s4=transfer(s2,s1,10u"g")
    @test typeof(s1)==LiquidStock
    @test typeof(s2)==SolidStock
    @test typeof(s3)==LiquidStock
    @test s4.quantity==50u"ml"
    @test s4.composition.ingredients[ingredient_db[findfirst(x->x.name=="iron_nitrate",ingredient_db)]]==200u"g/l"
    @test (s4.labware)==(s1.labware)
    @test s2.quantity==10u"g"
    s7,s5=transfer(s4,s3,3u"ml")
    @test s5.composition.ingredients[ingredient_db[findfirst(x->x.name=="iron_nitrate",ingredient_db)]]<s7.composition.ingredients[ingredient_db[findfirst(x->x.name=="iron_nitrate",ingredient_db)]] # concentration of iron nitrate should be less than the stock
    @test s5.quantity==43u"ml"
end 





