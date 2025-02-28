#include("./build_test_database.jl")


a=reconstruct_location(27,51)

b=reconstruct_location(25,51)
update( transfer!,a,b,1u"g"; ledger_id= update_ledger(52))


cache(a)
cache(b)

a=reconstruct_location(27,51)

b=reconstruct_location(25,51)

update( transfer!,a,b,7u"g"; ledger_id= insert_ledger(52))



## Movement cache repair 
a=reconstruct_location(5,15)

b=reconstruct_location(2,15) 

update( move_into!,b,a; ledger_id= update_ledger(16))

x=reconstruct_location(5)

cache(x) 
a=reconstruct_location(5,15)

c=reconstruct_location(3,15)

update( move_into!,c,a; ledger_id= update_ledger(16))


## Lock Cache repair 

update( lock!,a; ledger_id= insert_ledger(40))

update( deactivate!,a; ledger_id= insert_ledger(41) )
update( activate!,a; ledger_id= update_ledger(41))
x=reconstruct_location(9) 
cache(x)
update( set_attribute!,a,Temperature(42u"°C"); ledger_id= insert_ledger(10))
update( set_attribute!,a,Temperature(200u"°C"); ledger_id= update_ledger(10))