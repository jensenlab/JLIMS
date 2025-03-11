#include("./build_test_database.jl")


a=reconstruct_location(27,53)

b=reconstruct_location(25,53)
update( transfer!,a,b,1u"g"; ledger_id= update_ledger(54))


cache(a)
cache(b)

a=reconstruct_location(27,53)

b=reconstruct_location(25,53)

update( transfer!,a,b,7u"g"; ledger_id= insert_ledger(54))



## Movement cache repair 
a=reconstruct_location(5,16)

b=reconstruct_location(2,16) 

update( move_into!,b,a; ledger_id= update_ledger(17))

x=reconstruct_location(5)

cache(x) 
a=reconstruct_location(5,16)

c=reconstruct_location(3,16)

update( move_into!,c,a; ledger_id= update_ledger(17))


## Lock Cache repair 

update( lock!,a; ledger_id= insert_ledger(41))

update( deactivate!,a; ledger_id= insert_ledger(42) )
update( activate!,a; ledger_id= update_ledger(42))
x=reconstruct_location(9) 
cache(x)
update( set_attribute!,a,Temperature(42u"°C"); ledger_id= insert_ledger(11))
update( set_attribute!,a,Temperature(200u"°C"); ledger_id= update_ledger(11))