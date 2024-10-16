



"""
    parse_ingredient_csv(source)

parse CSVs that contain new ingredient definitions. Returns a vector of Ingredients

Example Table: 

| Name | Molecular_Weight | Class 
| :------ | ----------- | :-------:|
| water  | 18.01 | liquid | 
 
molecular weights are assumed to be in units of g/mol.

"""
function parse_chemical_csv(source)
    table=CSV.read(source,DataFrame)
    ingreds=Chemical[]
    types=Dict("solid"=>Solid,"liquid"=>Liquid)
    for row in eachrow(table)
        ing=types[row.Class](row.Name,row.Molecular_Weight*u"g/mol",missing)
        push!(ingreds,ing)
    end 
    return ingreds

end

function parse_strain_csv(source)
    table=CSV.read(source,DataFrame)
    strains=Strain[]
    for row in eachrow(table)
        ing=Strain(row.Name,row.Genus,row.Species,row.Notes)
        push!(strains,ing)
    end 
    return strains
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
        push!(comps,Composition(Dict(ingreds .=>quants)))
    end 
    return comps
end 


"""
    parse_container_csv(source)

parse CSVs that contain new container definitions. Returns a vector of containers

Example Table: 

| Name | Capacity | Unit | Rows | Cols | Vendor | Catalog |
| :------ | ----------- | -------| -------|-----| ------ | :------:| 
| conical_50ml  | 50 | ml | 1 | 1 | Thermo | 339652 | 
| plate_96 | 200 | µl | 8 | 12 | Thermo | 266120 |

"""
function parse_container_csv(source)
    table=CSV.read(source,DataFrame)
    n=nrow(table)
    conts=Container[]

    for i in 1:n
        name=String(table[i,:Name])
        cap=table[i,:Capacity]
        un=uparse(table[i,:Unit];unit_context=[Unitful,JensenLabUnits])
        capacity=cap*un
        shape=(table[i,:Rows],table[i,:Cols])
        vendor=String(table[i,:Vendor])
        catalog=String(table[i,:Catalog])
        push!(conts,Container(name,capacity,shape))
    end 

    return conts
end 



