
function reconstruct_location!(loc::Location,sequence_id::Integer=get_last_sequence_id(),time::DateTime=Dates.now();encumbrances=false)
    reconstruct_environment!(loc,sequence_id,time;encumbrances=encumbrances) # reconstructs full parent chain and environmental attributes
    reconstruct_children!(loc,sequence_id,time;encumbrances=encumbrances) # finds the current children of the location but doesn't fully reconstruct them, just creates a reference. 
    reconstruct_contents!(loc,sequence_id,time;encumbrances=encumbrances) # reconstructs stock and cost fields for wells

    return nothing 
end 



function reconstruct_location(location_id::Integer,sequence_id::Integer=get_last_sequence_id(),time::DateTime=Dates.now();encumbrances=false)
    

    n,t=get_location_info(location_id)

    loc=t(location_id,n)

    reconstruct_location!(loc,sequence_id,time;encumbrances=encumbrances)
    return loc 
end 






