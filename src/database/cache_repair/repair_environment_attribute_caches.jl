function repair_environment_attribute_caches(ledger_id::Integer)
    sequence_id=get_sequence_id(ledger_id)

    loc_id=get_environment_attribute_participant(ledger_id)
    cache_update_counter=0


    caches=get_attribute_caches(prt,sequence_id)
    
    for cache in eachrow(caches)

        cache_seq_id=cache.SequenceID
        old_loc=fetch_attribute_cache(loc_id,0,cache_seq_id)
        new_loc=reconstruct_attributes(loc_id,cache_seq_id,Dates.now(),cache_seq_id-1) # reconstruct but only use caches from before the one we are testing
        if attributes(old_loc) != attributes(new_loc) # cache has been invalidated --replace the cache 
            cache_ledger_id=get_last_ledger_id(cache_seq_id)
            cache_environment(new_loc,cache_seq_id)
            cache_update_counter +=1 
        end 
    end
   

    println("caches repaired: $cache_update_counter")



end


function get_environment_attribute_particpant(ledger_id::Integer)
        x="SELECT LedgerID,LocationID FROM EnvironmentAttributes WHERE LedgerID = $ledger_id"
        out1=query_db(x) 

        if nrow(out)==1 
            return out[1,"LocationID"]
        elseif nrow(out)==0 
            error("found no environment attribute entries for ledger id $ledger_id ")
        elseif nrow(out)> 1 
            error("found multiple environment attribute entries for ledger id $ledger_id")
        end 
    end 
