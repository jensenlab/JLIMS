




struct Strain 
    genus::String
    species::String
    strain::String
end 
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
genus(x::Strain) = x.genus
species(x::Strain)= x.species
strain(x::Strain)= x.strain

