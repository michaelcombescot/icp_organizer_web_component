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





export let registry = createActorTodosRegistry(registerID);

/////////////
// INDEXES //
/////////////

// users

export let usersIndexes : string[] = [];

export function getIndexUser() : ActorSubclass<_SERVICE_INDEX_TODOS_USERDATA> {
    let id = usersIndexes[Math.floor(Math.random() * usersIndexes.length)];
    return createActorIndexTodosUserData(id);
}

// groups

export let groupsIndexes : string[] = [];

export function getIndexGroup() : ActorSubclass<_SERVICE_INDEX_TODOS_GROUPS> {
    let id = groupsIndexes[Math.floor(Math.random() * groupsIndexes.length)];
    return createActorIndexTodosGroups(id);
}

/////////////
// BUCKETS //
/////////////

// users

export function getBucketUser(id: string) : ActorSubclass<_SERVICE_BUCKET_TODOS_USERDATA> {
    return createActorBucketTodosUserData(id);
}

// groups

export function getBucketGroup(id: string) : ActorSubclass<_SERVICE_BUCKET_TODOS_GROUPS> {
    return createActorBucketTodosGroups(id);
}