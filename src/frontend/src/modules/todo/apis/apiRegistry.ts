import { canisterId as registerID } from '../../../../../declarations/organizerIndexesRegistry/index';
import { createActor as createActorIndexesRegistry } from '../../../../../declarations/organizerIndexesRegistry';

import { _SERVICE as _SERVICE_INDEX } from '../../../../../declarations/organizerMainIndex/organizerMainIndex.did';
import { createActor as createActorMainIndex } from '../../../../../declarations/organizerMainIndex';

import { ActorSubclass } from '@dfinity/agent';
import { Principal } from '@dfinity/principal';

export class APIRegistry {
    static registry = createActorIndexesRegistry(registerID);

    static indexesUsers: Principal[] = []

    static async fetchIndexes(): Promise<void> {
        this.indexesUsers = await this.registry.handlerGetIndexes({ mainIndex: null });
    }

    static getMainIndex() : ActorSubclass<_SERVICE_INDEX> {
        let id = this.indexesUsers[Math.floor(Math.random() * this.indexesUsers.length)];
        return createActorMainIndex(id);
    }
}