#!/bin/bash

# then we do a call to add the registry to the coordinator
# for information, synthax if the param is a record is: (record { todosRegistryPrincipal = principal \"$(dfx canister id organizerTodosRegistry)\" })
dfx deploy coordinator
dfx generate coordinator
dfx ledger fabricate-cycles --canister coordinator # add cycles to the coordinator, will be needed to create indexes and buckets

# deploy one index registry
dfx deploy indexesRegistry --argument "(principal \"$(dfx canister id coordinator)\")"
dfx generate indexesRegistry

# add registry to coordinator
dfx canister call coordinator handlerAddRegistry "(principal \"$(dfx canister id indexesRegistry)\", variant { indexesRegistry })"



# then we generate all necessary code for the dynamically created canisters
dfx generate mainIndex

dfx generate groupsBucket
dfx generate usersBucket

# deploy internet identity
dfx deploy internet_identity
dfx generate internet_identity

# deploy frontend
# dfx deploy organizerFrontend

# create a first set of indexes
dfx canister call coordinator handlerCreateIndex '(variant { mainIndex })'