macro update(expr,ledger_id=append_ledger(),time=Dates.now()) 
    fun=eval(expr.args[1])
    upload_op=upload_operation(fun)
    return esc(quote 
        function update_transaction()
            $expr
            l_id=$ledger_id
            $upload_op(eval.($(expr.args[2:end]))...;ledger_id=l_id,time=$time)
            $process_update(l_id)
        end
        sql_transaction(update_transaction)
    end )
end 



function process_update(ledger_id::Integer)
        ids=get_all_ledger_ids(get_sequence_id(ledger_id))
        if length(ids) > 1 
            validate_operation_type(ids[end])==validate_operation_type(ids[end-1]) || error("the new operation is not the same type of operation as the previous one")
        end

        validate(ledger_id)
        cache_repair(ledger_id)
end

    


