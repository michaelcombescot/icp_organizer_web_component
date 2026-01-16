import { canisterId as registerID } from '../../../declarations/indexesRegistry/index';
import { createActor as createActorIndexesRegistry } from '../../../declarations/indexesRegistry';
import { IndexesKind } from '../../../declarations/indexesRegistry/indexesRegistry.did';


import { _SERVICE as _SERVICE_INDEX } from '../../../declarations/mainIndex/mainIndex.did';
import { createActor as createActorMainIndex } from '../../../declarations/mainIndex';

import { createActor as createActorGroupsBucket } from '../../../declarations/groupsBucket';
import { _SERVICE as _SERVICE_GROUPS } from '../../../declarations/groupsBucket/groupsBucket.did';

import { createActor as createActorUsersBucket } from '../../../declarations/usersBucket';
import { _SERVICE as _SERVICE_USERS } from '../../../declarations/usersBucket/usersBucket.did';

import { ActorSubclass } from '@dfinity/agent';
import { Principal } from '@dfinity/principal';
import { identity } from '../auth/auth';

export class Actors {
    public static SESSION_STORAGE_INDEXES_KEY = "sessionStorageIndexes";
    public static sessionStorageIndexes: Map<string, Principal[]> = new Map();
    public static SESSION_STORAGE_USER_BUCKET_KEY = "userBucket"
    public static userBucket: Principal

    static async fetchIndexes(): Promise<void> {
        try {
            let indexesResp = await createActorIndexesRegistry(registerID, { agentOptions: { identity } }).handlerGetIndexes();
            
            let indexMap = indexesResp.reduce((acc, entries) => {
                const key = Object.keys(entries[0])[0];

                if (!acc[key]) { acc[key] = [] }
                
                entries[1].forEach((principal) => acc[key].push(principal))

                return acc
            }, {} as Record<string, Principal[]>);

            console.log(indexMap)

            sessionStorage.setItem(this.SESSION_STORAGE_INDEXES_KEY, JSON.stringify(indexMap))
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
            sessionStorage.setItem(this.SESSION_STORAGE_USER_BUCKET_KEY, this.userBucket.toString())
        }
    }
        
    static getMainIndex() : ActorSubclass<_SERVICE_INDEX> {
        let mainIndexesJSON = sessionStorage.getItem(this.SESSION_STORAGE_INDEXES_KEY)!
        let mainIndexes = JSON.parse(mainIndexesJSON)["mainIndex"]

        if (mainIndexes === undefined) {
            throw new Error("No main index found");
        }

        let id = mainIndexes[Math.floor(Math.random() * mainIndexes.length)];

        return createActorMainIndex(Object.values(id)[0] as string, { agentOptions: { identity }});
    }

    static createGroupsBucketActor(principal: Principal) : ActorSubclass<_SERVICE_GROUPS> {
        return createActorGroupsBucket(principal, { agentOptions: { identity } });
    }

    static createUserBucketActor() : ActorSubclass<_SERVICE_USERS> {
        let bucket = sessionStorage.getItem(this.SESSION_STORAGE_USER_BUCKET_KEY)
        if (!bucket) {
            console.log("missing user bucker id")
        }

        return createActorUsersBucket(bucket!, { agentOptions: { identity } });
    }
}