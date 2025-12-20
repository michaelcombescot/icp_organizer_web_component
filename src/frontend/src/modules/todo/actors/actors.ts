import { canisterId as registerID } from '../../../../../declarations/organizerIndexesRegistry/index';
import { createActor } from '../../../../../declarations/organizerIndexesRegistry';
import { IndexesKind } from '../../../../../declarations/organizerIndexesRegistry/organizerIndexesRegistry.did';


import { _SERVICE as _SERVICE_INDEX } from '../../../../../declarations/organizerMainIndex/organizerMainIndex.did';
import { createActor as createActorMainIndex } from '../../../../../declarations/organizerMainIndex';

import { createActor as createActorGroupsBucket } from '../../../../../declarations/organizerGroupsBucket';
import { _SERVICE as _SERVICE_GROUPS } from '../../../../../declarations/organizerGroupsBucket/organizerGroupsBucket.did';

import { createActor as createActorUsersBucket } from '../../../../../declarations/organizerUsersBucket';
import { _SERVICE as _SERVICE_USERS } from '../../../../../declarations/organizerUsersBucket/organizerUsersBucket.did';

import { ActorSubclass } from '@dfinity/agent';
import { Principal } from '@dfinity/principal';

export class Actors {
    static registry = createActor(registerID);

    static indexes: Map<IndexesKind, Principal[]> = new Map();

    static async fetchIndexes(): Promise<void> {
        try {
            this.indexes = new Map(await this.registry.handlerGetIndexes());
        } catch (e) {
            console.error(`error fetching indexes: ${e}`);
        }
    }
        
    static getMainIndex() : ActorSubclass<_SERVICE_INDEX> {
        let mainIndexes = this.indexes.get({mainIndex: null})
        if (mainIndexes === undefined) {
            throw new Error("No main index found");
        }

        let id = mainIndexes[Math.floor(Math.random() * mainIndexes.length)];
        return createActorMainIndex(id);
    }

    static createGroupsBucketActor(principal: Principal) : ActorSubclass<_SERVICE_GROUPS> {
        return createActorGroupsBucket(principal);
    }

    static createUsersBucketActor(principal: Principal) : ActorSubclass<_SERVICE_USERS> {
        return createActorUsersBucket(principal);
    }
}