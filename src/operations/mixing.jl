
# mixing just performs the element wise operation on each chemical to compute the new composition
# addition and subtraction are very similar, this is a single routine for both addition and subtraction but we replace the  differences with "op". See the +/- overloads below. 
function mix(c1::Composition,c2::Composition;operation=+)
    new_liquids=Dict{Liquid,Unitful.Volume}()
    c1_liquids=liquids(c1)
    c1_lc=chemicals(c1_liquids)
    c2_liquids=liquids(c2)
    c2_lc=chemicals(c2_liquids)
    unique_chemicals=unique(vcat(c1_lc,c2_lc))
    for chem in unique_chemicals
        q1=0u"mL"
        q2=0u"mL"
        if chem in c1_lc
            q1=c1_liquids[chem]
        end
        if chem in c2_lc
            q2=c2_liquids[chem]
        end 
        tot=operation(q1,q2)
        tt=ustrip(tot)
        if tt== 0 
            continue
        elseif tt > 0 
            new_liquids[chem] = tot 
        else
            throw(MixingError(chem,": attempted to add a negative quantity to a composition"))
        end
    end
    new_solids=Dict{Solid,Unitful.Mass}() 
    c1_solids=solids(c1)
    c1_sc=chemicals(c1_solids)
    c2_solids=solids(c2)
    c2_sc=chemicals(c2_solids)
    unique_chemicals=unique(vcat(c1_sc,c2_sc))
    for chem in unique_chemicals
        q1=0u"g"
        q2=0u"g"
        if chem in c1_sc
            q1=c1_solids[chem]
        end
        if chem in c2_sc
            q2=c2_solids[chem] 
        end 
        tot=operation(q1,q2)
        tt=ustrip(tot)
        if tt== 0 
            continue
        elseif tt > 0 
            new_solids[chem] = tot 
        else
            throw(MixingError(chem,": attempted to add a negative quantity to a composition"))
        end
    end 
    return Composition(new_solids,new_liquids)
end 



# overload the +/- operators for mixing compositions. 
function +(c1::Composition,c2::Composition)
    return mix(c1,c2;operation=+)
end 

function -(c1::Composition,c2::Composition)
    return mix(c1,c2,operation=-)
end 



function +(c1::Composition)
    return c1
end 


function -(c1::Composition)
    return c1
end 

