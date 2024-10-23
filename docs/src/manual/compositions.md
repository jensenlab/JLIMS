```@meta
DocTestSetup = quote
    using JLIMS, Unitful
    glucose=Solid("glucose",180.156u"g/mol",1.54u"g/mL");
    water=Liquid("water",18u"g/mol",1u"g/mL");
    e_coli=Strain("e_coli_k12","Escherichia","coli","E. coli k12 strain");
end
```

# Compositions 

In JLIMS, a `Composition` is a collection of [Chemicals](@ref) that have individual concentrations


```@docs
Composition
```

!!! [Organisms](@ref) are treated separately in JLIMS. See Cultures. 


