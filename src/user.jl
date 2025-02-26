


"""
    register_lab(lab_module::Module)

Makes JLIMS aware of lab objects defined in a new lab module and allows the string macros [`@chem_str`](@ref) and [`@org_str`](@ref) to work with the objects.
When defining new lab objects, make sure to call `register_lab`. 

Example: 

```julia
# in a custom module 
module MyLab 
using JLIMS 

function __init__()
    ...
    JLIMS.register_lab(MyLab)
    ...
end 
end #module 
```

"""
function register_lab(lab_module::Module)
    push!(JLIMS.labmodules,lab_module) 
    if lab_module !== JLIMS 
        merge!(JLIMS.chemprops,_chemprops(lab_module))
        merge!(JLIMS.orgprops,_orgprops(lab_module))
    end 
    

end 