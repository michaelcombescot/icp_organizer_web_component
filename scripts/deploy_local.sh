#!/bin/bash

dfx deploy organizerTodosRegistry

# then we do a call to add the registry to the coordinator
# for information, synthax if the param is a record is: (record { todosRegistryPrincipal = principal \"$(dfx canister id organizerTodosRegistry)\" })
dfx deploy organizerCoordinator \
  --argument "(principal \"$(dfx canister id organizerTodosRegistry)\")"

# then we generate all necessary code for the dynamically created canisters
dfx generate organizerGroupsBucket
dfx generate organizerGroupsIndex

dfx generate organizerUsersBucket
dfx generate organizerUsersIndex

# create a first set of indexes
dfx canister call organizerCoordinator handlerAddIndex '(record { indexKind = variant { todosGroupsIndex } })'
dfx canister call organizerCoordinator handlerAddIndex '(record { indexKind = variant { todosUsersIndex } })'