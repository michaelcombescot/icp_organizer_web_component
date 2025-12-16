#!/bin/bash

dfx deploy organizerIndexesRegistry
dfx generate organizerIndexesRegistry

# then we do a call to add the registry to the coordinator
# for information, synthax if the param is a record is: (record { todosRegistryPrincipal = principal \"$(dfx canister id organizerTodosRegistry)\" })
dfx deploy organizerCoordinator \
  --argument "(principal \"$(dfx canister id organizerTodosRegistry)\")"

dfx generate organizerCoordinator

# then we generate all necessary code for the dynamically created canisters
dfx generate organizerTodosBucket
dfx generate organizerTodosIndex

dfx generate organizerUsersBucket
dfx generate organizerUsersIndex

# deploy internet identity
dfx deploy internet_identity
dfx generate internet_identity

# deploy frontend
dfx deploy organizerFrontend

# create a first set of indexes
dfx canister call organizerCoordinator handlerAddIndex '(variant { todosIndex })'
dfx canister call organizerCoordinator handlerAddIndex '(variant { usersIndex })'