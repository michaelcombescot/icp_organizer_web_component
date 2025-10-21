import { _SERVICE as _SERVICE_TODO } from '../../../../declarations/organizerTodos/organizerTodos.did';
import { _SERVICE as _SERVICE_USERDATA } from '../../../../declarations/organizerUsersData/organizerUsersData.did';
import { AuthClient } from '@dfinity/auth-client';
import { createActor as createActorTodos, canisterId as todosCanisterID } from '../../../../declarations/organizerTodos';
import { createActor as createActorUserData, canisterId as usersDataCanisterID } from '../../../../declarations/organizerUsersData';
import { canisterId as identityCanisterID } from '../../../../declarations/internet_identity/index';
import { ActorSubclass } from '@dfinity/agent';

console.log(todosCanisterID, usersDataCanisterID)

const identityProvider = process.env.DFX_NETWORK === 'ic' ?
                            'https://identity.ic0.app' // Mainnet
                            : `http://${identityCanisterID}.localhost:4943/`; // Local
let authClient = await AuthClient.create();
let identity = authClient.getIdentity();

export let actorTodos : ActorSubclass<_SERVICE_TODO>
export let actorUserData : ActorSubclass<_SERVICE_USERDATA>

export let isAuthenticated: boolean = await authClient.isAuthenticated();

export const login = async () => {
    await authClient.login({
        identityProvider,
        onSuccess: async () => {
            identity        = authClient.getIdentity();
            actorTodos      = createActorTodos(todosCanisterID, { agentOptions: { identity } });
            actorUserData   = createActorUserData(todosCanisterID, { agentOptions: { identity } });

            isAuthenticated = await authClient.isAuthenticated();

            window.location.reload();
        }
    });
};

export const logout = async () => {
    await authClient.logout()
    window.location.reload();
};