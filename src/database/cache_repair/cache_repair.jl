function operation_type(ledger_id::Integer)
    if isa_transfer(ledger_id)
        return repair_content_caches
    elseif isa_movement(ledger_id)
        return repair_movement_caches
    elseif isa_environment_attribute(ledger_id)
        return repair_environment_attribute_caches
    elseif isa_lock(ledger_id)
        return repair_lock_caches
    elseif isa_activity(ledger_id)
        return repair_activity_caches
    else
        error("cache repair operation not supported")
    end 

end 






"""
    cache_repair(ledger_id::Integer)

Repairs caches affected by updates, insertions, and deletions from the ledger.

When a cache is invalidated by an operation, a new cache is written to replace the old cache in future reconstructions. 

The old cache will still be utilized for reconstrutions triggered at a time before the cache was repaired.
"""
function cache_repair(ledger_id::Integer)

    operation=operation_type(ledger_id)

    operation(ledger_id)

end