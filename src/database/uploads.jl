


"""
    upload_ledger()
Add an entry to the ledger and return the ID of that entry.
"""
function upload_ledger() 
        #1) make an entry to the ledger
        current=get_last_ledger_id()
        ex=execute_db("""
        INSERT OR IGNORE INTO Ledger(Time)
        Values(datetime('now'))   
        """)
        #2) query the ledger to get the id of the entry you just made
        new=get_last_ledger_id()
        if current+1 != new 
            @warn("collision occurred, retrying ledger upload...")
            upload_ledger()
        else
            return new
        end 
end 





function upload_operation(fun::Function)
    opfun_dict=Dict(
        activate! => upload_activity,
        deactivate! => upload_activity,
        toggle_activity! => upload_activity,
        move_into! => upload_movement,
        transfer! => upload_transfer
    )
end 


"""
   upload_activity(location::Location)

Add an entry to the Activity table a [`Locaiton`](@ref)
    
Locations can be toggled between an active and inactive state. Activity can be used to show or hide locations in user interfaces.  
"""
function upload_activity(location::Location)
    ledger_id=upload_ledger()
    return execute_db("INSERT OR IGNORE INTO Activity(LedgerID,LocationID,IsActive,Time) Values($ledger_id,$(location_id(location)),$(Int(is_active(location))),datetime('now'))")
end 

function upload_attribute(attribute::Type{<:Attribute})
    return execute_db("INSERT OR IGNORE INTO Attributes(Attribute) Values($(string(attribute)))")
end 

function upload_barcode(bc::Barcode)
    loc_id=location_id(bc)
    if ismissing(loc_id)
        loc_id= "NULL"
    end 
    return execute_db("INSERT OR IGNORE INTO Barcodes(Barcode,LocationID,Name) Values($(string(barcode(bc))),$(loc_id),$(name(bc)))")
end 



function upload_location_type(l::Type{<:Location})
    return execute_db("INSERT OR IGNORE INTO LocationTypes(Name) Values($(string(l)))")
end 


function upload_new_location(name::String,t::Type{<:Location})
    execute_db("INSERT INTO Locations(Name,Type) Values($name,$(string(t)))")
    id=query_db("SELECT Max(ID) FROM Locations")
    return id[1,1]
end 

function upload_lock(location::Location)
    ledger_id=upload_ledger()
    return execute_db("INSERT OR IGNORE INTO Locks(LedgerID,LocationID,IsLocked,Time) Values($ledger_id,$(location_id(location)),$(Int(is_locked(location))),datetime('now'))")





"""
    upload_chemical(name::AbstractString,cid::Union{Integer,Missing},molecular_weight::Union{Real,Missing},density::Union{Real,Missing},class::AbstractString)

Upload a new chemical to the database. Use the [PubChem CID](https://pubchem.ncbi.nlm.nih.gov) to automatically parse chemical properties from the NIH PubChem database. 
"""
function upload_chemical(name::AbstractString,cid::Union{Integer,Missing},molecular_weight::Union{Real,Missing},density::Union{Real,Missing},class::AbstractString)
    x=ismissing(cid) ? "NULL" : cid
    y=ismissing(molecular_weight) ? "NULL" : molecular_weight
    z=ismissing(density) ? "NULL" : density
    return execute_db("
    INSERT OR IGNORE INTO Chemicals (Name, CID, Molar_Mass, Density, Class)
    Values('$name', $x, $y,$z,'$class')")
end 

function upload_chemical(name::AbstractString,cid::Integer,class::AbstractString)
molecular_weight,density=get_mw_density(cid)
upload_chemical(name,cid,molecular_weight,density,class)
end 


"""
    upload_strain(name::AbstractString,genus::AbstractString,species::AbstractString,NCBI_ID::AbstractString,notes::AbstractString="")

Upload a new strain to the database. Include the [NCBI Taxonomy ID](https://www.ncbi.nlm.nih.gov/Taxonomy/taxonomyhome.html/index.cgi) to standardize strain types.
"""
function upload_strain(name::AbstractString,genus::AbstractString,species::AbstractString,NCBI_ID::Union{Integer,Missing},notes::Union{AbstractString,Missing}="")
    a=ismissing(NCBI_ID) ? "NULL" : NCBI_ID
    b=ismissing(notes) ? "" : notes 
    execute_db("""INSERT OR IGNORE INTO Strains(Name,Genus,Species,NCBI_ID,Notes) Values('$name','$genus','$species',$a,'$b')""")
end 
   

"""
    upload_composition(name::AbstractString) 

Upload a new composition name to the database.
"""
function upload_composition(name::AbstractString) 
    return execute_db("INSERT OR IGNORE INTO Compositions (Name) Values('$name')")
end

"""
    upload_composition_chemical(name::AbstractString,chemical::AbstractString,concentration::Real,unit::AbstractString) 

Upload a new composition-chemical pair to the database.
"""
function upload_composition_chemical(name::AbstractString,chemical::AbstractString,concentration::Real,unit::AbstractString)
    concentration >=0 ? nothing : throw(DomainError(concentration,"Concentrations must be nonnegative."))
    upload_composition(name)
    return execute_db("INSERT OR IGNORE INTO CompositionChemicals(CompositionID,ChemicalID,Concentration,Unit) Values ('$name','$chemical',$concentration,'$unit')")
end


"""
   upload_source(compname::AbstractString,location_type::AbstractString) 

Upload a new composition source that ties a `compname` to a `location_type`

##Example:
    The reagent D-glucose has a `compname` "D-glucose" which arrives in a "D-glucose" bottle.
"""
function upload_source(compname::AbstractString,location_type::AbstractString)
    return execute_db("INSERT OR IGNORE INTO Sources(CompositionID,LocationType) Values('$compname','$location_type')")
end 

"""
    upload_well(loc_id::Integer,well_idx::Integer)

Upload a new well in location `loc_id` in well index `well_idx`. 
 
See `generate_location` to automatically generate wells of relevant locations. 
"""
function upload_well(loc_id::Integer,well_idx::Integer)
    return execute_db("INSERT OR IGNORE INTO Wells(LocationID,Well_Index) Values($loc_id,$well_idx)")
end 

""" 
    upload_source_transfer(sourceID::Integer,wellID::Integer,quantity::Real,unit::AbstractString,price::Real)

commit a source transfer to the ledger. Transfer a `quantity` of `sourceID` to `wellID`. price will be used to reconstruct the price of reagents for experiments.  
"""
function upload_source_transfer(sourceID::Integer,wellID::Integer,quantity::Real,unit::AbstractString,price::Real)
    price >=0 ? nothing : throw(DomainError(price,"price must be non-negative."))
    quantity >= 0 ? nothing : throw(DomainError(quantity,"quantity must be non-negative"))
    ledger_id=upload_ledger()
    return execute_db("INSERT OR IGNORE INTO SourceTransfers(LedgerID,SourceID,WellID,Quantity,Unit,Time,Price) Values($ledger_id,$sourceID,$wellID,$quantity,'$unit',datetime('now'),$price)")
end 



"""
    upload_strain_transfer(strainID::AbstractString,wellID::Integer)

commit a strain transfer to the ledger. Initial transfer a strain into a well from the outside world. Analgous to a source transfer but for strains. 
"""
function upload_strain_transfer(strainID::AbstractString,wellID::Integer)
    ledger_id=upload_ledger()
    return execute_db("INSERT OR IGNORE INTO StrainTransfers(LedgerID,StrainID,WellID,Time) Values($ledger_id,'$strainID',$wellID,datetime('now'))")
end 

"""
    upload_transfer(sourceID::Integer,destinationID::Integer,quantity::Real,unit::AbstractString,configuration::AbstractString)

commit a transfer of `quantity` from  well `sourceID` to well `destinationID` using a particular robot `configuration`
"""
function upload_transfer(sourceID::Integer,destinationID::Integer,quantity::Real,unit::AbstractString,configuration::AbstractString)
    ledger_id=upload_ledger()
    return execute_db("""INSERT INTO Transfers(LedgerID,Source,Destination,Quantity,Unit,Time,Configuration) Values('$ledger_id','$sourceID','$destinationID','$quantity','$unit',datetime('now'),'$configuration')""")
end 

"""
    upload_barcode(Barcode::AbstractString,Name::AbstractString="")

Upload an optionally named barcode to the database that can be assigned to a location.
"""
function upload_barcode(Barcode::AbstractString,Name::AbstractString="")
    return execute_db("INSERT OR IGNORE INTO Barcodes(Barcode,Name) Values('$Barcode','$Name')")
end 




"""
    upload_location_type(name::AbstractString,vendor::Union{AbstractString,Missing},catalog::Union{AbstractString,Missing},well_rows::Integer,well_cols::Integer,well_capacity::Real,unit::AbstractString,is_constrained::Bool)

Upload a new locaton type to the database. `is_constrained` enforces constraints found in the location constraints table. Adding a location constraint for a location type automatically updates `is_constrained`
"""
function upload_location_type(name::AbstractString,vendor::Union{AbstractString,Missing},catalog::Union{AbstractString,Missing},well_rows::Integer,well_cols::Integer,well_capacity::Real,unit::AbstractString,is_constrained::Bool)
    a=ismissing(vendor) ? "NULL" : vendor
    b=ismissing(catalog) ? "NULL" : catalog
    return execute_db("INSERT OR IGNORE INTO LocationTypes(Name,Vendor,Catalog,WellRows,WellCols,WellCapacity,Unit,IsConstrained) Values('$name','$a','$b',$well_rows,$well_cols,$well_capacity,'$unit',$(Int(is_constrained)))")
end 


"""
    upload_location(name::AbstractString,type::AbstractString)

Upload a new instance of location `type` with human-readable name `name`

ex. upload_location("conical_50ml", 
"""
function upload_location(name::AbstractString,type::AbstractString)
    return execute_db("INSERT OR IGNORE INTO Locations(Name,Type) Values('$name','$type')")
end



function upload_location_constraint(parent::AbstractString,child::AbstractString,occupancy::Real)
    0 <= occupancy <= 1 ? nothing : throw(DomainError(occupancy,"occupancy must be a real number between zero and one."))
    !is_constrained(parent) ? constrain_location(parent) : nothing  # update IsConstrained on the parent location type if it isn't already constrained 
    return execute_db("INSERT OR IGNORE INTO LocationConstraints(ParentType, ChildType,Occupancy) Values('$parent','$child',$occupancy)")
end 

function upload_movement(childid::Integer,parentid::Union{Integer,Missing},is_locked::Bool=false)
    parent= ismissing(parentid) ? "NULL" : parentid
    ledger_id=upload_ledger()
    return execute_db("INSERT OR IGNORE INTO Movements(LedgerID,Child,Parent,IsLocked,Time) Values($ledger_id,$childid,$parent,$(Int(is_locked)),datetime('now'))")
end 


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

function upload_environmental_attribute(attribute::AbstractString) 
    execute_db("""INSERT OR IGNORE INTO EnvironmentalAttributes(Attribute) Values('$attribute')""")
end 



function upload_environment(locationid::Integer,attribute::AbstractString,value::Real,unit::AbstractString)
    ledger_id=upload_ledger()
    execute_db("""INSERT OR IGNORE INTO Environments(LedgerID,LocationID,Attribute,Value,Unit,Time) Values('$ledger_id',$locationid,'$attribute','$value','$unit',datetime('now'))""")
end 



function upload_experiment(name::AbstractString,user::AbstractString,ispublic::Bool)
    execute_db("""INSERT INTO Experiments(Name,User,IsPublic,Time) Values('$name','$user','$ispublic',datetime('now'))""")
    x=query_db("""SELECT Max(ID) FROM Experiments WHERE Name = '$name'""",returnDataFrame=true)
    return x[1,1]
end 

function upload_encumbered_activity(e_id::Integer,loc_id::Integer,is_active::Bool)
    execute_db("""Insert INTO EncumberedActivity(EncumbranceID,LocationID,IsActive) Values($e_id,$loc_id,$(Int(is_active)))""")
end 