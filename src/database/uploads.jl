






function upload_operation(fun::Function)
    opfun_dict=Dict(
        activate! => upload_activity,
        deactivate! => upload_activity,
        toggle_activity! => upload_activity,
        lock! => upload_lock,
        unlock! => upload_lock,
        toggle_lock! => upload_lock,
        move_into! => upload_movement,
        transfer! => upload_transfer,
        set_attribute! => upload_environment_attribute,
        assign_barcode! => update_barcode
    )
    return opfun_dict[fun]
end 


"""
    upload(fun::Funciton,args...;time=DateTime=Dates.now())

Execute and upload a JLIMS operation to a CHESS Database. If an error occurs in either execution or uploading, [`upload`](@ref) will return an error and rollback any changes to the database

See [`upload_operation`](@ref) for the list of supported JLIMS operations. 

#Examples 

```julia
julia> @connect_SQLite "test_db.db" 

julia> upload(transfer!,locA,locB,5u"g")
julia> upload(set_attribute!,locA,Temperature(10u"°C"))
```
"""
function upload(fun::Function,args...;ledger_id=append_ledger(),time::DateTime=Dates.now())
    up_fun=upload_operation(fun) 
    function upload_transaction()
        fun(args...)
        up_fun(args...;ledger_id=ledger_id,time=time) 
    end 
    sql_transaction(upload_transaction)
    return ledger_id
end 


    




"""
   upload_activity(location::Location)

Add an entry to the Activity table a [`Locaiton`](@ref)
    
Locations can be toggled between an active and inactive state. Activity can be used to show or hide locations in user interfaces.  
"""
function upload_activity(location::Location;ledger_id::Integer=append_ledger(),time::DateTime=Dates.now())
    upload_time=db_time(time)
    execute_db("INSERT OR IGNORE INTO Activity(LedgerID,LocationID,IsActive,Time) Values($ledger_id,$(location_id(location)),$(Int(is_active(location))),$upload_time)")
    return nothing
end 

function upload_attribute(attribute::Attribute)
    execute_db("INSERT OR IGNORE INTO Attributes(Attribute,BaseUnit) Values('$(string(typeof(attribute)))','$(string(attribute_unit(attribute)))')")
    return nothing 
end 
#=
function upload_barcode(bc::Barcode)
    loc_id=location_id(bc)
    if ismissing(loc_id)
        loc_id= "NULL"
    end 
    return execute_db("INSERT OR IGNORE INTO Barcodes(Barcode,LocationID,Name) Values($(string(barcode(bc))),$(loc_id),$(name(bc)))")
end 
=#


function upload_location_type(l::Type{<:Location})
    execute_db("INSERT OR IGNORE INTO LocationTypes(Name) Values('$(string(l))')")
    return nothing 
end 


function upload_new_location(name::String,t::Type{<:Location})
    upload_location_type(t)
    execute_db("INSERT INTO Locations(Name,Type) Values('$name','$(string(t))')")
    id=query_db("SELECT Max(ID) FROM Locations")
    return id[1,1]
end 

function upload_lock(location::Location;ledger_id::Integer=append_ledger(),time::DateTime=Dates.now())
    upload_time=db_time(time)
    execute_db("INSERT OR IGNORE INTO Locks(LedgerID,LocationID,IsLocked,Time) Values($ledger_id,$(location_id(location)),$(Int(is_locked(location))),$upload_time)")
    return nothing
end 

function upload_component(chem::Chemical)
    execute_db("INSERT OR IGNORE INTO Components(ComponentHash, Type) Values($(hash(chem)),'Chemical')")
    id=get_component_id(chem)
    mw=ustrip(uconvert(u"g/mol",molecular_weight(chem)))
    d=ustrip(uconvert(u"g/mL",density(chem)))
    execute_db("INSERT OR IGNORE INTO Chemicals(Name,ComponentID,Type,MolecularWeight,Density,CID) Values('$(name(chem))',$(id),'$(string(typeof(chem)))',$(mw),$(d),$(pubchemid(chem)))")
    return id
end 

function upload_component(str::Organism)
    execute_db("INSERT OR IGNORE INTO Components(ComponentHash,Type) Values($(hash(str)),'Organism')")
    id=get_component_id(str)
    execute_db("INSERT OR IGNORE INTO Organisms(ComponentID,Genus,Species,Strain) Values($(id),'$(genus(str))','$(species(str))','$(strain(str))')")
    return id
end 




"""
    upload_transfer(sourceID::Integer,destinationID::Integer,quantity::Real,unit::AbstractString,configuration::AbstractString)

commit a transfer of `quantity` from  well `sourceID` to well `destinationID` using a particular robot `configuration`
"""
function upload_transfer(source::Well,destination::Well,quant::Union{Unitful.Mass,Unitful.Volume},configuration::AbstractString="";ledger_id::Integer=append_ledger(),time::DateTime=now())
    upload_time=db_time(time)
    execute_db("""INSERT INTO Transfers(LedgerID,Source,Destination,Quantity,Unit,Time,Configuration) Values($ledger_id,$(location_id(source)),$(location_id(destination)),$(ustrip(quant)),'$(string(unit(quant)))',$upload_time,'$configuration')""")
    return nothing
end 
 


function upload_movement(parent::Location,child::Location,lock::Bool=false;ledger_id::Integer=append_ledger(),time::DateTime=now())
    upload_time=db_time(time)
    execute_db("INSERT OR IGNORE INTO Movements(LedgerID,Parent,Child,Time) Values($ledger_id,$(location_id(parent)),$(location_id(child)),$upload_time)")
    if lock
        upload_lock(child;time=time) # only needed if the lock flag is true. This means that the lock state has changed (you had to be unlocked to move in the first place)
    end 
    return nothing 
end 

function upload_environment_attribute(loc::Location,attr::Attribute;ledger_id::Integer=append_ledger(),time::Dates.DateTime=now()) 
    upload_time=db_time(time)
    val=quantity(attr)
    upload_attribute(attr)
    execute_db("""INSERT OR IGNORE INTO EnvironmentAttributes(LedgerID,LocationID,Attribute,Value,Unit,Time) Values($ledger_id,$(location_id(loc)),'$(string(typeof(attr)))',$(ustrip(val)),'$(string(unit(val)))',$upload_time)""")
    return nothing
end 


function upload_tag(comment::String,ledger_id::Integer=get_last_ledger_id();time::DateTime=Dates.now())
    upload_time=db_time(time)
    execute_db("INSERT INTO Tags(LedgerID,Comment,Time) Values($ledger_id,'$comment',$upload_time)")
    return nothing
end 

function upload_barcode(bc::Barcode)
    loc_id=location_id(bc)
    if ismissing(loc_id)
        loc_id="NULL"
    end 
    execute_db("INSERT OR IGNORE INTO Barcodes(Barcode,LocationID,Name) Values('$(string(barcode(bc)))',$loc_id,'$(name(bc))')")
end 

function update_barcode(bc::Barcode,loc::Location;kwargs...)
    loc_id=location_id(bc)
    if ismissing(loc_id)
        loc_id="NULL"
    elseif loc_id != location_id(loc) 
        error("barcode location id does not match the supplied location")
    end 
    execute_db("UPDATE Barcodes SET LocationID = $loc_id WHERE Barcode = '$(string(barcode(bc)))'")
    return nothing 
end 

