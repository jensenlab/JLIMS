function repair_movement_caches(ledger_id::Integer)


    sequence_id=get_sequence_id(ledger_id)

    prt,chld=get_movement_participants(ledger_id)
    cache_update_counter=0
    # repair the parent's child caches 

    caches=get_child_caches(prt,sequence_id)
    
    for cache in eachrow(caches)

        cache_seq_id=cache.SequenceID
        old_loc,foot=fetch_child_cache(loc_id,0,cache_seq_id)
        new_loc=reconstruct_children(loc_id,cache_seq_id,Dates.now(),cache_seq_id-1) # reconstruct but only use caches from before the one we are testing

        if children(old_loc) != children(new_loc) # cache has been invalidated --replace the cache 
            cache_ledger_id=get_last_ledger_id(cache_seq_id)
            cache_children(new_loc,cache_ledger_id)
            cache_update_counter +=1 
        end 
    end

    # repair the child's parent caches 

    caches=get_parent_caches(chld,sequence_id)
    for cache in eachrow(caches)

        cache_seq_id=cache.SequenceID
        old_loc,foot=fetch_parent_cache(loc_id,0,cache_seq_id)
        new_loc=reconstruct_parent(loc_id,cache_seq_id,Dates.now(),cache_seq_id-1) # reconstruct but only use caches from before the one we are testing

        if JLIMS.parent(old_loc) != JLIMS.parent(new_loc) # cache has been invalidated --replace the cache 
            cache_ledger_id=get_last_ledger_id(cache_seq_id)
            cache_parent(new_loc,cache_ledger_id)
            cache_update_counter +=1 
        end 
    end
   

    println("caches repaired: $cache_update_counter")


end 



function get_movement_participants(ledger_id::Integer)
    x="SELECT LedgerID,Parent,Child FROM Movements WHERE LedgerID = $ledger_id"
    out=query_db(x) 
    if nrow(out)==1 
        return out[1,"Parent"],out[1,"Child"]
    elseif nrow(out)==0 
        error("found no movement entries for ledger id $ledger_id ")
    elseif nrow(out)> 1 
        error("found multiple movement entries for ledger id $ledger_id")
    end 
end 