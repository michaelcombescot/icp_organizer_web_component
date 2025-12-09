#!/bin/bash

dfx deploy organizerTodosRegistry
dfx deploy organizerCoordinator

dfx generate organizerGroupsBucket
dfx generate organizerGroupsIndex

dfx generate organizerUsersBucket
dfx generate organizerUsersIndex

# then we do a call to add the registry to the coordinator

...