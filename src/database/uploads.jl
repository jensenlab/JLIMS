


"""
    upload_ledger(sequenceID::Integer)
Add an entry to the ledger and return the ID of that entry.
"""
function upload_ledger(sequenceID::Integer)
    time=db_time(Dates.now())
    execute_db("""
    INSERT OR IGNORE INTO Ledger(SequenceID,Time)
    Values($sequenceID,$time)   
    """)
    out=query_db("SELECT Max(ID) FROM Ledger")[1,:]
    return out["Max(ID)"]
end 

function upload_ledger() 
    seq_id=get_last_sequence_id()+1
    return upload_ledger(seq_id)
end 





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



macro upload(expr,time=Dates.now()) 
    fun=eval(expr.args[1])
    upload_op=upload_operation(fun)
    return esc(quote 
        $expr
        $upload_op(eval.($(expr.args[2:end]))...; time=$time)
    end )
end 








"""
   upload_activity(location::Location)

Add an entry to the Activity table a [`Locaiton`](@ref)
    
Locations can be toggled between an active and inactive state. Activity can be used to show or hide locations in user interfaces.  
"""
function upload_activity(location::Location;time::DateTime=Dates.now())
    upload_time=db_time(time)
    ledger_id=upload_ledger()
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

function upload_lock(location::Location;time::DateTime=Dates.now())
    ledger_id=upload_ledger()
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

function upload_component(str::Strain)
    execute_db("INSERT OR IGNORE INTO Components(ComponentHash,Type) Values($(hash(str)),'Strain')")
    id=get_component_id(str)
    execute_db("INSERT OR IGNORE INTO Strains(ComponentID,Genus,Species,Strain) Values($(id),'$(genus(str))','$(species(str))','$(strain(str))')")
    return id
end 




"""
    upload_transfer(sourceID::Integer,destinationID::Integer,quantity::Real,unit::AbstractString,configuration::AbstractString)

commit a transfer of `quantity` from  well `sourceID` to well `destinationID` using a particular robot `configuration`
"""
function upload_transfer(source::Well,destination::Well,quant::Union{Unitful.Mass,Unitful.Volume},configuration::AbstractString="";time::DateTime=now())
    ledger_id=upload_ledger()
    upload_time=db_time(time)
    execute_db("""INSERT INTO Transfers(LedgerID,Source,Destination,Quantity,Unit,Time,Configuration) Values($ledger_id,$(location_id(source)),$(location_id(destination)),$(ustrip(quant)),'$(string(unit(quant)))',$upload_time,'$configuration')""")
    return nothing
end 
 


function upload_movement(parent::Location,child::Location,lock::Bool=false;time::DateTime=now())
    ledger_id=upload_ledger()
    upload_time=db_time(time)
    execute_db("INSERT OR IGNORE INTO Movements(LedgerID,Parent,Child,Time) Values($ledger_id,$(location_id(parent)),$(location_id(child)),$upload_time)")
    if lock
        upload_lock(child;time=time) # only needed if the lock flag is true. This means that the lock state has changed (you had to be unlocked to move in the first place)
    end 
    return nothing 
end 

function upload_environment_attribute(loc::Location,attr::Attribute;time::Dates.DateTime=now()) 
    ledger_id=upload_ledger()
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


#=
function upload_protocol(exp_id,name::AbstractString) 
    execute_db("""
    INSERT INTO Protocols(ExperimentID,Name) Values('$exp_id','$name');
    """)
    x=query_db("""
    SELECT Max(ID) FROM Protocols WHERE Name='$name'""";returnDataFrame=true)
    return x[1,1]
end 



function upload_encumbrance(protocol_id::Integer, is_enforced::Bool)
    execute_db("""
    INSERT INTO Encumbrances(ProtocolID) Values ('$protocol_id')""")
    e_id=query_db("""
    SELECT Max(ID) FROM Encumbrances""";returnDataFrame=true)[1,1]
    upload_encumbrance_enforcement(e_id,is_enforced)
    return e_id
end 

function upload_encumbrance_enforcement(encumbrance_id::Integer,is_enforced::Bool)
    ledger_id=upload_ledger()
    execute_db("""INSERT INTO EncumbranceEnforcement(LedgerID,EncumbranceID,IsEnforced,Time) Values('$ledger_id','$encumbrance_id','$(Int64(is_enforced))',datetime('now'))""")
end 
    



function upload_encumbered_transfer(encumberid::Integer,source::Integer,destination::Integer,quantity::Real,unit::AbstractString,instrument_type::AbstractString)
    execute_db("""
    INSERT INTO EncumberedTransfers(EncumbranceID,Source,Destination,Quantity,Unit,InstrumentType) Values('$encumberid','$source','$destination','$quantity','$unit','$instrument_type')""")
end 

function upload_encumbered_source_transfer(encumberid::Integer,source::Integer,wellid::Integer,quantity::Real, unit::AbstractString,price_estimate::Real)
    execute_db("""
    INSERT INTO EncumberedSourceTransfers(EncumbranceID,SourceID,WellID,Quantity,Unit,PriceEstimate) Values('$encumberid','$source','$wellid','$quantity','$unit','$price_estimate')""")

end 

function upload_encumbered_strain_transfer(encumberid::Integer,strainID::AbstractString,wellID::Integer)
    return execute_db("INSERT OR IGNORE INTO EncumberedStrainTransfers(EncumbranceID,StrainID,WellID) Values($encumberid,'$strainID',$wellID)")
end 

function upload_encumbered_environment(encumberid::Integer,locationid::Integer,attribute::AbstractString,value::Real,unit::AbstractString)
    execute_db("""INSERT INTO EncumberedEnvironments(EncumbranceID,LocationID,Attribute,Value,Unit) Values('$encumberid',$locationid,'$attribute','$value','$unit')""")
end 



function upload_encumbered_movement(encumberid::Integer,childid::Integer,parentid::Union{Integer,Missing},is_locked::Bool=false)
    parent= ismissing(parentid) ? "NULL" : parentid
    execute_db("""INSERT INTO EncumberedMovements(EncumbranceID,Child,Parent,IsLocked) Values($encumberid,$childid,$parent,$(Int(is_locked)))""")
end 


function upload_instrument_type(name::AbstractString,manufacturer::Union{AbstractString,Missing})
    a= ismissing(manufacturer) ? "NULL" : manufacturer
    execute_db("INSERT OR IGNORE INTO InstrumentTypes(Name,Manufacturer) Values('$name','$a')")
end 

function upload_instrument(name::AbstractString,type::AbstractString,location_id::Union{Integer,Missing})
    loc = ismissing(location_id) ? "NULL" : location_id
    execute_db("""INSERT OR IGNORE INTO Instruments(Name,InstrumentType,LocationID) Values('$name','$type',$loc)""")
end 


function upload_configuration(config::AbstractString,instrument_type::AbstractString)
    execute_db("""INSERT OR IGNORE INTO Configurations(Configuration, InstrumentType) Values('$config','$instrument_type')""")
end 








function upload_experiment(name::AbstractString,user::AbstractString,ispublic::Bool)
    execute_db("""INSERT INTO Experiments(Name,User,IsPublic,Time) Values('$name','$user','$ispublic',datetime('now'))""")
    x=query_db("""SELECT Max(ID) FROM Experiments WHERE Name = '$name'""",returnDataFrame=true)
    return x[1,1]
end 

function upload_encumbered_activity(e_id::Integer,loc_id::Integer,is_active::Bool)
    execute_db("""Insert INTO EncumberedActivity(EncumbranceID,LocationID,IsActive) Values($e_id,$loc_id,$(Int(is_active)))""")
end 
=#