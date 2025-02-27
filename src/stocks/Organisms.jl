



"""
    struct Organism

A unique species (and strain). organisms can be combined with [`Stock`](@ref) objects to create [`Culture`](@ref) objects

`Organsim` objects have three properties: 
1) `genus`: The strain's taxonomic genus
2) `species`: The Strains taxonomic species
3) `strain`: The strain's identifier


"""
struct Organism
    genus::String
    species::String
    strain::String
end 

"""
    macro organism(labsymb, genus, species, strain)

A macro to quickly define a new `Organism` object and import it into the workspace under `labname`. 

"""
macro organism(labsymb,genus,species,strain)

    expr =Expr(:block)
    push!(expr.args,quote 
        Base.@__doc__ $JLIMS.@organism_symbols $labsymb $genus $species $strain
        end 
    )

    push!(expr.args,quote
        $labsymb
    end )

    esc(expr)
end 



macro organism_symbols(labsymb,genus,species,strain)
    ls= Symbol(labsymb)
    ln = Meta.quot(ls)
    docstr= """
            $labsymb

       The organism $genus $species $strain  

        See also: [`Organism`](@ref)
        """
    oprops = :($genus,$species,$strain)  
    esc(quote

        $(orgprops_expr(__module__,ln,oprops))
        const global $ls = Organism($genus,$species,$strain)
        @doc $docstr $ls 
    end)
end 





function orgprops_expr(m::Module,n,orgprops)
    if m === JLIMS
        :($(_orgprops(JLIMS))[$n]= $orgprops)
    else
        # We add the chemical properties to dictionaries in both JLIMS and the module `m` so that the factor is available in both
        quote 
            $(_orgprops(m))[$n]=$orgprops
            $(_orgprops(JLIMS))[$n]=$orgprops
        end 
    end 
end 




macro org_str(organism)
    ex = Meta.parse(organism)
    labmods = [JLIMS]
    for m in JLIMS.labmodules
        # Find registered lab extension modules which are also loaded by
        # __module__ (required so that precompilation will work).
        if isdefined(__module__, nameof(m)) && getfield(__module__, nameof(m)) === m
            push!(labmods, m)
        end
    end
    esc(lookup_organisms(labmods, ex))
end


function orgparse(str; org_context=JLIMS)
    ex = Meta.parse(str)
    eval(lookup_organisms(org_context, ex))
end
function lookup_organisms(labmods, sym::Symbol)
    has_organism = m->(isdefined(m,sym) && orgstr_check_bool(getfield(m, sym)))
    inds = findall(has_organism, labmods)
    if isempty(inds)
        # Check whether chemical exists in the global list to give an improved
        # error message.
        hintidx = findfirst(has_organism, labmodules)
        if hintidx !== nothing
            hintmod = labmodules[hintidx]
            throw(ArgumentError(
                """Symbol `$sym` was found in the globally registered lab module $hintmod
                   but was not in the provided list of lab modules $(join(labmods, ", ")).

                   (Consider `using $hintmod` in your module if you are using `@chem_str`?)"""))
        else            all_orgs = vcat(map(x->filter(y-> orgstr_check_bool(getfield(x,y)),names(x)),labmods)...)
            idxs=findall(String(sym),String.(all_orgs),StringDistances.Levenshtein();min_score=0.5)
            max_return = 4 
            outlen=min(length(idxs),max_return)
            idxs=idxs[1:outlen]
            ch=String.(all_orgs[idxs])
            stmt="~no suggestions available~"
            if outlen > 1 
                stmt = string("Did you mean: ",join(ch[1:(end-1)],", ",),", or ",ch[end],"?")
            elseif outlen == 1
                stmt = string("Did you mean: $(ch[1])?")
            end 
            throw(ArgumentError("""Symbol $sym could not be found in lab modules $labmods
            
            $stmt
            """))
        end
    end

    m = labmods[inds[end]]
    u = getfield(m, sym)

    any(u != u1 for u1 in getfield.(labmods[inds[1:(end-1)]], sym)) &&
        @warn """Symbol $sym was found in multiple registered lab modules.
                 We will use the one from $m."""
    return u
end

orgstr_check_bool(::Organism) =true 
orgstr_check_bool(::Any) =false










Base.show(io::IO,str::Organism)=print(io, name(str))
"""
    genus(x::Organism)
Access the `genus` property of a `Organism` object.
"""
genus(x::Organism) = x.genus
"""
    species(x::Organism)
Access the `species` property of a `Organism` object.
"""
species(x::Organism)= x.species
"""
    strain(x::Organism)
Acces the  `strain` property of a `Organism` object.
"""
strain(x::Organism)= x.strain


"""
    name(x::Organism)
return the full name of a Organism 
"""
name(x::Organism) = "$(genus(x)) $(species(x)) $(strain(x))"