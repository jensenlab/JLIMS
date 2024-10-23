# Quick Start Guide 

JLIMS allows users to represent physical lab objects as digital entities. 

```jldoctest overview 
julia> using JLIMS,Unitful
```

## Define new ingredients and labware 

```jldoctest overview 
julia> water=Liquid("water",18u"g/mol",1u"g/mL");

julia> glucose=Solid("glucose",180.156u"g/mol",1.54u"g/mL");

julia> e_coli=Strain("e_coli_k12","Escherichia","coli","E. coli k12 strain");

julia> conical_50ml=Container("50mL Conical",50u"mL",(1,1)); # a 50 ml conical has a single well in a 1x1 grid

julia> well1=Well(1,"conical1",1,conical_50ml);

julia> well2=Well(2,"conical2",1,conical_50ml);

julia> well3=Well(3,"conical3",1,conical_50ml);

```

## Create reagent compositions 

```jldoctest overview 
julia> pure_glucose=Composition(Dict(glucose => 100u"percent"));

julia> pure_water=Composition(Dict(water => 100u"percent"));
```

## Create reagent stocks 

```jldoctest overview 
julia> glucose_stock=Stock(pure_glucose,20u"g",well1)
20.0 g Mixture (1 ingredient(s))
 Ingredient  Concentration
───────────────────────────
 glucose     100.0 %
Well ID: 1,Labware ID: conical1 (50mL Conical => 50 mL (1 by 1)), Well 1

julia> water_stock=Stock(pure_water,50u"ml",well2)
50.0 mL Solution (1 ingredient(s))
 Ingredient  Concentration
───────────────────────────
 water       100.0 %
Well ID: 2,Labware ID: conical2 (50mL Conical => 50 mL (1 by 1)), Well 1

julia> new_stock=Stock(Empty(),missing,well3)
Empty Composition
Well ID: 3,Labware ID: conical3 (50mL Conical => 50 mL (1 by 1)), Well 1
```


## Stock Transfers

```jldoctest overview 

julia> glucose_stock,new_stock=transfer(glucose_stock,new_stock,3u"g");

julia> print(new_stock)
3.0 g Mixture (1 ingredient(s))
 Ingredient  Concentration
───────────────────────────
 glucose     100.0 %
Well ID: 3,Labware ID: conical3 (50mL Conical => 50 mL (1 by 1)), Well 1

```


