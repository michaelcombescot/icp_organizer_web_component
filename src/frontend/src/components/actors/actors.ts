import { _SERVICE as _SERVICE_TODOS_REGISTRY } from '../../../../declarations/organizerTodosRegistry/organizerTodosRegistry.did';
import { createActor as createActorTodosRegistry, canisterId as canisterIDTodosRegistry } from '../../../../declarations/organizerTodosRegistry';

import { _SERVICE as _SERVICE_INDEX_TODOS_GROUPS } from '../../../../declarations/organizerGroupsIndex/organizerGroupsIndex.did';
import { createActor as createActorIndexTodosGroups, canisterId as canisterIDTodosIndexGroups } from '../../../../declarations/organizerGroupsIndex';
import { _SERVICE as _SERVICE_BUCKET_TODOS_GROUPS } from '../../../../declarations/organizerGroupsBucket/organizerGroupsBucket.did';
import { createActor as createActorBucketTodosGroups, canisterId as canisterIDTodosBucketGroups } from '../../../../declarations/organizerGroupsBucket';

import { _SERVICE as _SERVICE_INDEX_TODOS_USERDATA } from '../../../../declarations/organizerUsersIndex/organizerUsersIndex.did';
import { createActor as createActorIndexTodosUserData, canisterId as canisterIDTodosIndexUserData } from '../../../../declarations/organizerUsersIndex';
import { _SERVICE as _SERVICE_BUCKET_TODOS_USERDATA } from '../../../../declarations/organizerUsersBucket/organizerUsersBucket.did';
import { createActor as createActorBucketTodosUserData, canisterId as canisterIDTodosBucketUserData } from '../../../../declarations/organizerUsersBucket';

import { ActorSubclass } from '@dfinity/agent';
import { identity } from '../auth/auth';
import { Principal } from '@dfinity/principal';

// registry
export type ActorTodosRegistry = ActorSubclass<_SERVICE_TODOS_REGISTRY>

export function getActorTodosRegistry(canisterID: string | Principal) : ActorTodosRegistry {
    return createActorTodosRegistry(canisterID, { agentOptions: { identity } });
};

// todos groups
export type ActorIndexTodosGroups = ActorSubclass<_SERVICE_INDEX_TODOS_GROUPS>

export function getActorIndexTodosGroups(canisterID: string | Principal) : ActorIndexTodosGroups {
    return createActorIndexTodosGroups(canisterID, { agentOptions: { identity } });
};

export type ActorBucketTodosGroups = ActorSubclass<_SERVICE_BUCKET_TODOS_GROUPS>

export function getActorBucketTodosGroups(canisterID: string | Principal) : ActorBucketTodosGroups {
    return createActorBucketTodosGroups(canisterID, { agentOptions: { identity } });
};

// todos user data
export type ActorIndexTodosUserData = ActorSubclass<_SERVICE_INDEX_TODOS_USERDATA>

export function getActorIndexTodosUserData(canisterID: string | Principal) : ActorIndexTodosUserData {
    return createActorIndexTodosUserData(canisterID, { agentOptions: { identity } });
};

export type ActorBucketsTodosUserData = ActorSubclass<_SERVICE_BUCKET_TODOS_USERDATA>

export function getActorBucketTodosUserData(canisterID: string | Principal) : ActorBucketsTodosUserData {
    return createActorBucketTodosUserData(canisterID, { agentOptions: { identity } });
};