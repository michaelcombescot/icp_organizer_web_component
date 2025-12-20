#!/bin/bash

dfx deploy organizerIndexesRegistry
dfx generate organizerIndexesRegistry

# then we do a call to add the registry to the coordinator
# for information, synthax if the param is a record is: (record { todosRegistryPrincipal = principal \"$(dfx canister id organizerTodosRegistry)\" })
dfx deploy organizerCoordinator \
  --argument "(principal \"$(dfx canister id organizerIndexesRegistry)\")"

dfx generate organizerCoordinator
dfx ledger fabricate-cycles --canister organizerCoordinator # add cycles to the coordinator, will be needed to create indexes and buckets

# then we generate all necessary code for the dynamically created canisters
dfx generate organizerMainIndex

dfx generate organizerGroupsBucket
dfx generate organizerUsersBucket

# deploy internet identity
dfx deploy internet_identity
dfx generate internet_identity

# deploy frontend
# dfx deploy organizerFrontend

# create a first set of indexes
dfx canister call organizerCoordinator handlerAddIndex '(variant { mainIndex })'