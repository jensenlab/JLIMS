


"""
    reconstruct_location!(loc::Location,sequence_id::Integer=get_last_sequence_id(),time::DateTime=Dates.now();encumbrances=false)

Reconstruct the entire state of a [`Location`](@ref) `location` in a CHESS Database. 

# Optional Arguments 
1) `sequence_id`: set the reconstruction to happen at a particular sequence point in the ledger. Default is the current maximum sequence ID in the Database. 
2) `time`: only consider operations that were recorded in the CHESS ledger before  `time`. `time` uses [Dates.jl](https://docs.julialang.org/en/v1/stdlib/Dates/) to standardize the time formatting. Default is Dates.now()
3) `encumbrances`: Include encumbrances in the reconstruction. Encumbrances are future operations that are not in the ledger but have been planned.

Note: Combining these optional arguments allows users to traverse the state of any location at any time, past or present. Encumbrances are enforced as they would have been at the `sequence_id` and `time` of the reconstruction.

See Also: [`reconstruct_location`](@ref)
"""
function reconstruct_location!(loc::Location,sequence_id::Integer=get_last_sequence_id(),time::DateTime=Dates.now();encumbrances=false)
    reconstruct_environment!(loc,sequence_id,time;encumbrances=encumbrances) # reconstructs full parent chain and environmental attributes
    reconstruct_children!(loc,sequence_id,time;encumbrances=encumbrances) # finds the current children of the location but doesn't fully reconstruct them, just creates a reference. 
    reconstruct_contents!(loc,sequence_id,time;encumbrances=encumbrances) # reconstructs stock and cost fields for wells
    reconstruct_lock!(loc,sequence_id,time;encumbrances=encumbrances) # reconstructs the locked state (recall locks prevent movement)
    reconstruct_activity!(loc,sequence_id,time;encumbrances=encumbrances) # reconstructs the activity state 
    return nothing 
end 






"""
    reconstruct_location(location_id::Integer,sequence_id::Integer=get_last_sequence_id(),time::DateTime=Dates.now();encumbrances=false)

Reconstruct the entire state of location in a CHESS Database using only a location_id

# Optional Arguments
1) `sequence_id`: set the reconstruction to happen at a particular sequence point in the ledger. Default is the current maximum sequence ID in the Database. 
2) `time`: only consider operations that were recorded in the CHESS ledger before  `time`. `time` uses [Dates.jl](https://docs.julialang.org/en/v1/stdlib/Dates/) to standardize the time formatting. Default is Dates.now()
3) `encumbrances`: Include encumbrances in the reconstruction. Encumbrances are future operations that are not in the ledger but have been planned.

Note: Combining these optional arguments allows users to traverse the state of any location at any time, past or present. Encumbrances are enforced as they would have been at the sequence_id and time of the reconstruction.

See Also: [`reconstruct_location!`](@ref)
"""
function reconstruct_location(location_id::Integer,sequence_id::Integer=get_last_sequence_id(),time::DateTime=Dates.now();encumbrances=false)
    

    n,t=get_location_info(location_id)

    loc=t(location_id,n)

    reconstruct_location!(loc,sequence_id,time;encumbrances=encumbrances)
    return loc 
end 






