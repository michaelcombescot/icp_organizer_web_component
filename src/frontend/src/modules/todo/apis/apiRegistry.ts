import { _SERVICE as _SERVICE_INDEX_TODOS_USERDATA } from '../../../../../declarations/organizerUsersIndex/organizerUsersIndex.did';
import { createActor as createActorIndexTodosUserData, canisterId as canisterIDTodosIndexUserData } from '../../../../../declarations/organizerUsersIndex';
import { _SERVICE as _SERVICE_BUCKET_TODOS_USERDATA } from '../../../../../declarations/organizerUsersBucket/organizerUsersBucket.did';
import { createActor as createActorBucketTodosUserData, canisterId as canisterIDTodosBucketUserData } from '../../../../../declarations/organizerUsersBucket';

import { _SERVICE as _SERVICE_INDEX_TODOS_GROUPS } from '../../../../../declarations/organizerGroupsIndex/organizerGroupsIndex.did';
import { createActor as createActorIndexTodosGroups } from '../../../../../declarations/organizerGroupsIndex';
import { _SERVICE as _SERVICE_BUCKET_TODOS_GROUPS } from '../../../../../declarations/organizerGroupsBucket/organizerGroupsBucket.did';
import { createActor as createActorBucketTodosGroups } from '../../../../../declarations/organizerGroupsBucket';

import { canisterId as registerID } from '../../../../../declarations/organizerTodosRegistry/index';
import { createActor as createActorTodosRegistry } from '../../../../../declarations/organizerTodosRegistry';

import { ActorSubclass } from '@dfinity/agent';
import { Principal } from '@dfinity/principal';


export type IndexKind = { 'todosGroupsIndex' : null } |
  { 'todosUsersIndex' : null };


export let registry = createActorTodosRegistry(registerID);
export var indexesUsers: Principal[] = []
export let indexesGroups: Principal[] = []

export async function fetchIndexes() {
    (await registry.handlerGetIndexes()).forEach((res) => {
        switch ( res[0] ) {
            case { 'todosGroupsIndex' : null } :
                indexesGroups.push(res[1]);
                break;
            case { 'todosUsersIndex' : null } :
                indexesUsers.push(res[1]);
                break;
        }
    })
}

/////////////
// INDEXES //
/////////////

// users

export function getIndexUser() : ActorSubclass<_SERVICE_INDEX_TODOS_USERDATA> {
    let id = indexesUsers[Math.floor(Math.random() * indexesUsers.length)];
    return createActorIndexTodosUserData(id);
}

// groups

export function getIndexGroup() : ActorSubclass<_SERVICE_INDEX_TODOS_GROUPS> {
    let id = indexesGroups[Math.floor(Math.random() * indexesGroups.length)];
    return createActorIndexTodosGroups(id);
}