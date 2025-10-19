import { _SERVICE } from '../../../../declarations/organizerTodos/organizerTodos.did';
import { AuthClient } from '@dfinity/auth-client';
import { createActor as createActorTodos, canisterId as todosCanisterID } from '../../../../declarations/organizerTodos';
import { createActor as createActorUserData, canisterId as usersDataCanisterID } from '../../../../declarations/organizerUsersData';
import { canisterId as identityCanisterID } from '../../../../declarations/internet_identity/index';

console.log(todosCanisterID, usersDataCanisterID)

const identityProvider = process.env.DFX_NETWORK === 'ic' ?
                            'https://identity.ic0.app' // Mainnet
                            : `http://${identityCanisterID}.localhost:4943/`; // Local
let authClient = await AuthClient.create();
let identity = authClient.getIdentity();

export let actorTodos : ActorSubclass<_SERVICE>

export let isAuthenticated: boolean = await authClient.isAuthenticated();

export const login = async () => {
    await authClient.login({
        identityProvider,
        onSuccess: async () => {
            updateActor();
            window.location.reload();
        }
    });
};

export const updateActor = async () => {
    identity = authClient.getIdentity();
    actorTodos = createActorTodos(todosCanisterID, {
      agentOptions: {
        identity
      }
    });
    
    isAuthenticated = await authClient.isAuthenticated();
}

export const logout = async () => {
    await authClient.logout()
    window.location.reload();
};