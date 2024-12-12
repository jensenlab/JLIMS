



"""
    struct Strain

Represents a strain of an organism. Strains can be combined with [`Stock`](@ref) objects to create [`Culture`](@ref) objects

`Strain` objects have three properties: 
1) `genus`: The strain's taxonomic genus
2) `species`: The Strains taxonomic species
3) `strain`: The strain's identifier


"""
struct Strain 
    genus::String
    species::String
    strain::String
end 

"""
    macro strain(labname, genus, species, strain)

A macro to quickly define a new `Strain` object and import it into the workspace under `labname`. 

"""
macro strain(labname, genus, species, strain)

    n=Symbol(labname)
    g=string(genus)
    s=string(species)
    st=string(strain)

    if isdefined(__module__,n) || isdefined(JLIMS,n)
        error("Strain $n already defined")
    end 


    return esc(quote
        const $n = JLIMS.Strain($g,$s,$st)
    end)
end 

Base.show(io::IO,str::Strain)=print(io, "$(genus(str)[1]). $(species(str)) $(strain(str)))")
"""
    genus(x::Strain)
Access the `genus` property of a `Strain` object.
"""
genus(x::Strain) = x.genus
"""
    species(x::Strain)
Access the `species` property of a `Strain` object.
"""
species(x::Strain)= x.species
"""
    strain(x::Strain)
Acces the  `strain` property of a `Strain` object.
"""
strain(x::Strain)= x.strain


"""
    name(x::Strain)
return the full name of a Strain 
"""
name(x::Strain) = "$(genus(x)) $(species(x)) $(strain(x))"