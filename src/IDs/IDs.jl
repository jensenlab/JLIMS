using UUIDs

function id()
    return string(UUIDs.uuid1())
end 

function id(n)
    ids=["" for i in 1:n]
    for i in 1:n
        ids[i]=string(UUIDs.uuid1())
        sleep(0.001)
    end 

    return ids
end 





"""
    named_id(name::String)

Generate a 20 character universally unique ID and append it to name. 

## Arguments
* `name`: a human generated name for the object 
"""
function named_id(name::String)
    return string(name,"\$",id())
end 