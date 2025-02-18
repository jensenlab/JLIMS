include("./build_test_database.jl")


a=reconstruct_location(27,51)

b=reconstruct_location(25,51)
@update transfer!(a,b,1u"g") update_ledger(52)


cache(a)
cache(b)

a=reconstruct_location(27,51)

b=reconstruct_location(25,51)

@update transfer!(a,b,7u"g") insert_ledger(52)
