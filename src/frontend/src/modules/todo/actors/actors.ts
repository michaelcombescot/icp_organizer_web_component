import { canisterId as registerID } from '../../../../../declarations/indexesRegistry/index';
import { createActor as createActorIndexesRegistry } from '../../../../../declarations/indexesRegistry';
import { IndexesKind } from '../../../../../declarations/indexesRegistry/indexesRegistry.did';


import { _SERVICE as _SERVICE_INDEX } from '../../../../../declarations/mainIndex/mainIndex.did';
import { createActor as createActorMainIndex } from '../../../../../declarations/mainIndex';

import { createActor as createActorGroupsBucket } from '../../../../../declarations/groupsBucket';
import { _SERVICE as _SERVICE_GROUPS } from '../../../../../declarations/groupsBucket/groupsBucket.did';

import { createActor as createActorUsersBucket } from '../../../../../declarations/usersBucket';
import { _SERVICE as _SERVICE_USERS } from '../../../../../declarations/usersBucket/usersBucket.did';

import { ActorSubclass } from '@dfinity/agent';
import { Principal } from '@dfinity/principal';
import { identity } from '../../../auth/auth';

export class Actors {
    static indexes: Map<string, Principal[]> = new Map();

    public static userBucketLocalKey = "userBucket"
    public static userBucket: Principal

    private static getVariantTag(variant: IndexesKind): string {
        return Object.keys(variant)[0];
    }

    static async fetchIndexes(): Promise<void> {
        try {
            let indexesResp = await createActorIndexesRegistry(registerID, { agentOptions: { identity } }).handlerGetIndexes();
            this.indexes = new Map( indexesResp.map((entries) => [this.getVariantTag(entries[0]), entries[1]]) );
        } catch (e) {
            console.error(`error fetching indexes: ${e}`);
        }
    }

    static async fetchUserBucket() {
        let res = await Actors.getMainIndex().handlerFetchOrCreateUser();
        if ( "err" in res) {
            console.log(res.err)
        } else {
            this.userBucket = res.ok
            sessionStorage.setItem(this.userBucketLocalKey, this.userBucket.toString())
        }
    }
        
    static getMainIndex() : ActorSubclass<_SERVICE_INDEX> {
        let mainIndexes = this.indexes.get("mainIndex")
        if (mainIndexes === undefined) {
            throw new Error("No main index found");
        }

        let id = mainIndexes[Math.floor(Math.random() * mainIndexes.length)];
        return createActorMainIndex(id, { agentOptions: { identity }});
    }

    static createGroupsBucketActor(principal: Principal) : ActorSubclass<_SERVICE_GROUPS> {
        return createActorGroupsBucket(principal, { agentOptions: { identity } });
    }

    static createUserBucketActor() : ActorSubclass<_SERVICE_USERS> {
        let bucket = sessionStorage.getItem(this.userBucketLocalKey)
        if (!bucket) {
            console.log("missing user bucker id")
        }

        return createActorUsersBucket(bucket!, { agentOptions: { identity } });
    }
}