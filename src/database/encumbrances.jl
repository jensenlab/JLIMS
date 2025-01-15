function encumber_operation(fun::Function)
    opfun_dict=Dict(
        activate! => JLIMS.encumber_activity,
        deactivate! => JLIMS.encumber_activity,
        toggle_activity! => JLIMS.encumber_activity,
        lock! => JLIMS.encumber_lock,
        unlock! => JLIMS.encumber_lock,
        toggle_lock! => JLIMS.encumber_lock,
        move_into! => JLIMS.encumber_movement,
        transfer! => JLIMS.encumber_transfer,
        set_attribute! => JLIMS.encumber_environment_attribute
    )
    return opfun_dict[fun]
end 



macro encumber(protocol_id,expr) 
    fun=eval(expr.args[1])
    encumber_op=encumber_operation(fun)
    return esc(quote 
        $expr
        e_id=upload_encumbrance(Int($protocol_id))
        $encumber_op(e_id,eval.($(expr.args[2:end]))...)
    end )
end 
#=
macro protocol(experiment_id,name, expr)
    #=
    expt=Int(eval(experiment_id))
    expt_name=string(eval(name))
    if !isa(expt,Integer)
        error("provide an integer experiment id")
    end 

    if !isa(expt_name,String)
        error("provide a string protocol name")
    end 
    =#
    hd=expr.head
    args=expr.args
    if hd == :block 
        return esc(quote 
            expt=$experiment_id
            expt_name=$name
            p_id=upload_protocol(expt,expt_name)
            println("trigger_up")
            for arg in $args
                if arg isa Expr
                    println(typeof(arg))
                    println(typeof(p_id))
                    println(arg)
                    @encumber p_id arg
                end
            end 
        end)
    else
        return esc(quote
            expt=$experiment_id
            expt_name=$name
            p_id=upload_protocol(expt,expt_name)
            println("trigger_low")
            @encumber p_id $expr
        end)
    end 
end 
=#


    


function upload_experiment(name::AbstractString,user::String,is_public=false;time=Dates.now())

    execute_db("""INSERT INTO Experiments(Name,User,IsPublic,Time) Values('$name','$user',$(Int(is_public)),'$(string(time))')""")
    ex_id=query_db("""SELECT Max(ID) FROM Experiments""")
    return ex_id[1,1]
end 

function upload_protocol(exp_id::Integer,name::AbstractString,estimate=Dates.Time(0)) 
    execute_db("""
    INSERT INTO Protocols(ExperimentID,Name,EstimatedTime) Values($exp_id,'$name','$(string(estimate))');
    """)
    x=query_db("""
    SELECT Max(ID) FROM Protocols""")
    return x[1,1]
end 

function upload_encumbrance(protocol_id::Integer, is_enforced::Bool=true;time=Dates.now())
    execute_db("""
    INSERT INTO Encumbrances(ProtocolID) Values ($protocol_id)""")
    e_id=query_db("""
    SELECT Max(ID) FROM Encumbrances""")[1,1]
    upload_encumbrance_enforcement(e_id,is_enforced;time=time)
    return e_id
end 

function upload_encumbrance_enforcement(encumbrance_id::Integer,is_enforced::Bool;time=Dates.now())
    ledger_id=upload_ledger()
    execute_db("""INSERT INTO EncumbranceEnforcement(LedgerID,EncumbranceID,IsEnforced,Time) Values($ledger_id,$encumbrance_id,$(Int64(is_enforced)),'$(string(time))')""")
end 
    



function encumber_transfer(encumberid::Integer, source::Well,destination::Well,quant::Union{Unitful.Mass,Unitful.Volume},configuration::AbstractString="")
    execute_db("""
    INSERT INTO EncumberedTransfers(EncumbranceID,Source,Destination,Quantity,Unit,Configuration) Values($encumberid,$(location_id(source)),$(location_id(destination)),$(ustrip(quant)),'$(string(unit(quant)))','$configuration')""")
    return nothing
end 



function encumber_environment_attribute(encumberid::Integer,loc::Location,attr::Attribute)
    upload_attribute(typeof(attr))
    val=value(attr)
    execute_db("""INSERT INTO EncumberedEnvironments(EncumbranceID,LocationID,Attribute,Value,Unit) Values($encumberid,$(location_id(loc)),'$(string(typeof(attr)))',$(ustrip(val)),'$(string(unit(val)))')""")
    return nothing
end 



function encumber_movement(encumberid::Integer,parent::Location,child::Location,lock::Bool=false)
    execute_db("""INSERT INTO EncumberedMovements(EncumbranceID,Parent,Child) Values($encumberid,$(location_id(parent)),$(location_id(child)))""")
    if lock
        encumber_lock(child;time=time) # only needed if the lock flag is true. This means that the lock state has changed (you had to be unlocked to move in the first place)
    end
    return nothing 
end 


function encumber_lock(encumberid::Integer,loc::Location)
    execute_db("INSERT INTO EncumberedLocks(EncumbranceID,LocationID,IsLocked) Values($encumberid,$(location_id(loc)),$(Int(is_locked(loc))))")
    return nothing
end 

function encumber_activity(encumberid::Integer,loc::Location)
    execute_db("INSERT INTO EncumberedActivity(EncumbranceID,LocationID,IsActive) Values($encumberid,$(location_id(loc)),$(Int(is_active(loc))))")
    return nothing 
end 


function encumber_cache(encumberid::Integer, loc::Location)
    parent_id=location_id(parent(loc))
    if isnothing(parent_id)
        parent_id="NULL"
    end
    children_id=cache_children(children(loc))
    stock_id=cache(stock(loc))
    attr_id=cache(attributes(loc))
    locked=Int(is_locked(loc))
    active=Int(is_active(loc))
    id=query_db("SELECT ID FROM CacheSets WHERE ParentID = $parent_id AND ChildSetID = $children_id AND AttributeSetID = $attr_id AND StockID = $stock_id AND IsLocked = $locked AND IsActive =$active")
    if nrow(id)==0 
        execute_db("INSERT INTO CacheSets(ParentID,ChildSetID,AttributeSetID, StockID,IsLocked,IsActive) Values($parent_id,$children_id,$attr_id,$stock_id,$locked,$active)")
        id=query_db("SELECT Max(ID) FROM CacheSets")[1,1]
    else
        id=id[1,1]
    end
    loc_id=location_id(loc)

    execute_db("INSERT INTO EncumberedCaches(EncumbranceID,LocationID,CacheSetID) Values($encumberid,$loc_id,$id)")
    return nothing
end 

