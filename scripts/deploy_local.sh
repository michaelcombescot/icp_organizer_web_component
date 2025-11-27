#!/bin/bash

dfx deploy registry
dfx deploy coordinator
# do the command to save the coordinator principal in the resitry calling setCoordinator
# do the command to create the first index calling the coordinator

# we need to generate the code for all buckets, in order to be able to:
# - transfer the wasm file to the maintenance canister when we need to upgrade the code of a bucket
# - having the declarations available for the frontend to access a bucket directly without requesting the associated index
dfx generate organizerUsersDataBucket
...