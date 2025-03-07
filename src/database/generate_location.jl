


function generate_location(type::Type{<:Location},name::String=string(UUIDs.uuid4()))
    upload_location_type(type)
    loc_id = upload_new_location(name,type)
    return type(loc_id,name)
end 
    




"""
    generate_(type::Type{<:Labware},name::String=string(UUIDs.uuid4()))

Generate a a `type` Labware and fill it with empty wells. 
"""
function generate_location(type::Type{<:Labware},name::String=string(UUIDs.uuid4()))
    upload_location_type(type)
    loc_id=upload_new_location(name,type)
    lw=type(loc_id,name)
    sh=shape(lw)
    welltype=childtype(lw)
    wells=Location[]
    for col in 1:sh[2]
        for row in 1:sh[1]
            well=generate_location(welltype,alphabet_code(row)*string(col))
            well.parent=lw
            lw.children[row,col]=well
            push!(wells,well)
        end 
    end
    cache(lw)
    cache.(wells)
    return lw
end 



function alphabet_code(n) 
    
    alphabet=collect('A':'Z')
    k=length(alphabet)
    return repeat(alphabet[mod(n-1,k)+1],cld(n,k))
end 

    