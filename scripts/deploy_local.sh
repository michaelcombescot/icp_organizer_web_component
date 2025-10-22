#!/bin/bash

dfx deploy organizerMaintenance
dfx deploy organizerUsersDataIndex
dfx deploy organizerTodosIndex

# we need to generate the code for all buckets, in order to be able to:
# - transfer the wasm file to the maintenance canister when we need to upgrade the code of a bucket
# - having the declarations available for the frontend to access a bucket directly without requesting the associated index
dfx generate organizerUsersDataBucket
dfx generate organizerTodosBucket

dfx deploy organizerFrontend

dfx deploy internet_identity