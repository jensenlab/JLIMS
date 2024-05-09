



"""
    parse_ingredient_csv(source)

parse CSVs that contain new ingredient definitions. Returns a vector of Ingredients

Example Table: 

| Name | Molecular_Weight | Class 
| :------ | ----------- | :-------:|
| water  | 18.01 | liquid | 
 
molecular weights are assumed to be in units of g/mol.

"""
function parse_ingredient_csv(source)
    table=CSV.read(source,DataFrame)
    table.Class.=Symbol.(table.Class)
    table.Molecular_Weight.=table.Molecular_Weight * u"g/mol"
    n=nrow(table)
    ingreds=Ingredient[]
    for i in 1:n
        push!(ingreds,Ingredient(Vector(table[i,:])...))
    end 

    return ingreds

end



"""
    parse_composition_csv(source,ingredients::Vector{Ingredient})

parse CSVs that contain new composition definitions. Returns a vector of compositions

Example Table: 

| Name | Ingredient | Concentration | Unit |
| :------ | ----------- | -------| :-------:|
| glucose_10x  | glucose | 10 | g/l | 
| glucose_10x | water | 100 | percent |
 
each composition name can have multiple ingredients in the definition. 

"""
function parse_composition_csv(source,ingredients::Vector{Ingredient})
    table=CSV.read(source,DataFrame)
    compnames=String.(unique(table.Name))
    comps=Composition[]

    for i in eachindex(compnames)
        idxs=findall(x->x==compnames[i],table.Name)
        ingred_names=table[idxs,:Ingredient]
        ingreds=map(x->ingredients[findfirst(y->y.name==x,ingredients)],ingred_names)
        conc=table[idxs,:Concentration]
        uns=table[idxs,:Unit]
        quants=conc.*Unitful.uparse.(uns;unit_context=[Unitful,JensenLabUnits])
        push!(comps,Composition(compnames[i],Dict(ingreds .=>quants)))
    end 
    return comps
end 


"""
    parse_container_csv(source)

parse CSVs that contain new container definitions. Returns a vector of containers

Example Table: 

| Name | Volume | Unit | Rows | Cols | Vendor | Catalog |
| :------ | ----------- | -------| -------|-----| ------ | :------:| 
| conical_50ml  | 50 | ml | 1 | 1 | Thermo | 339652 | 
| plate_96 | 200 | µl | 8 | 12 | Thermo | 266120 |

"""
function parse_container_csv(source)
    table=CSV.read(source,DataFrame)
    n=nrow(table)
    conts=Container[]

    for i in 1:n
        name=table[i,:Name]
        vol=table[i,:Volume]
        un=uparse(table[i,:Unit];unit_context=[Unitful,JensenLabUnits])
        volume=vol*un
        shape=(table[i,:Rows],table[i,:Cols])
        vendor=table[i,:Vendor]
        catalog=table[i,:Catalog]
        push!(conts,Container(name,volume,shape,vendor,catalog))
    end 

    return conts
end 



