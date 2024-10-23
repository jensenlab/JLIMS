```@meta
DocTestSetup = quote
    using JLIMS, Unitful
end
```
# Ingredients 


Ingredients are the elementary units of JLIMS objects. All JLIMS objects are made by combining one or more ingredients. In JLIMS, ingredeients can either be [Chemicals](@ref) or [Organisms](@ref). 


## Chemicals 

Chemicals are pure physical substances that have unique properties. JLIMS stores three chemical properties 

- **name**: a unique identifier of the chemical 
- **molecular weight**: the chemical's molecular weight, if known or determinable
- **density**: the chemical's density, if known or determinable 

JLIMS uses the molecular weight and density of chemicals to facilitate automatic unit conversions when mixtures of different ingredients are combined. 

In JLIMS, we classify chemicals as either a `Solid` or a `Liquid` depending on how that chemical behaves at standard temperature and pressure.  
```jldoctest ingredients
julia> glucose=Solid("glucose",180.156u"g/mol",1.54u"g/mL");


julia> water=Liquid("water",18u"g/mol",1u"g/mL");
```

!!! JLIMS uses the Untiful.jl package to manage units for all quantities. 

## Organisms

Organisms are a unique species of life. JLIMS provides a `Strain` constructor to store properties of organisms 

- **name**: A unique identifier of the strain 
- **genus**: The strain's genus
- **species**: The strain's species
- **notes**: additional information about the strain, such as genetic modifications

```jldoctest ingredients
julia> e_coli=Strain("e_coli_k12","Escherichia","coli","E. coli k12 strain");
```

Chemicals and Organisms share a type hierarchy 

```julia 

Chemical <: Ingredient
Solid <: Chemical
Liquid <: Chemical 
Organism <: Ingredient 
Strain <: Organism
```

```jldoctest ingredients
julia> water isa Liquid
true 
julia> water isa Ingredient
true
julia> e_coli isa Ingredient
true
```

