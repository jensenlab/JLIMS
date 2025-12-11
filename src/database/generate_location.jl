






"""
    generate_location(type::Type{<:Labware},name::String=string(UUIDs.uuid4()),child_namer::Vararg{Function}=plate_namer)

Generate a a `type` Location and fill it with empty well if applicable. 

Optionally add a variable number of functions to recursively name children of generated labware. naming functions should take two arguments `row` and `col` and return a string. The default is `plate_namer` 

See also: [`plate_namer`](@ref). 
"""
function generate_location(type::Type{<:Location},name::String=string(UUIDs.uuid4()),child_namer::Vararg{Function}=plate_namer)
    upload_location_type(type)
    loc_id=upload_new_location(name,type)
    lw=type(loc_id,name)
    sh=shape(lw)
    welltype=childtype(lw)
    wells=Location[]
    for col in 1:sh[2]
        for row in 1:sh[1]
            well=generate_location(welltype,child_namer[1](row,col),child_namer[2:end]...)
            well.parent=lw
            lw.children[row,col]=well
            push!(wells,well)
        end 
    end
    cache(lw)
    if length(wells) > 0 
        cache.(wells)
    end 
    return lw
end 



function generate_unregistered_location(type::Type{<:Location},name::String=string(UUIDs.uuid4()),child_namer::Vararg{Function}=plate_namer)
    loc_id = 0 
    lw=type(loc_id,name)
    sh=shape(lw)
    welltype=childtype(lw)
    for col in 1:sh[2]
        for row in 1:sh[1]
            well=generate_unregistered_location(welltype,child_namer[1](row,col),child_namer[2:end]...)
            well.parent=lw
            lw.children[row,col]=well
        end 
    end
    return lw
end 

"""
    plate_namer(row,col)

Return the microplate standard name for a row and col coordinate 

Ex. plate_namer(1,1)  = "A1" , plate_namer(8,12) = "H12" 
"""
function plate_namer(row,col)
    return alphabet_code(row) * string(col) 
end 


function alphabet_code(n) 
    
    alphabet=collect('A':'Z')
    k=length(alphabet)
    return repeat(alphabet[mod(n-1,k)+1],cld(n,k))
end 

    