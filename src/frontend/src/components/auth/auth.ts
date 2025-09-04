import { type _SERVICE } from '../../../../declarations/backend/backend.did'
import { AuthClient } from '@dfinity/auth-client';
import { createActor } from '../../../../declarations/backend';
import { canisterId as backendCanisterID } from '../../../../declarations/backend';
import { canisterId as identityCanisterID } from '../../../../declarations/internet_identity/index';

const identityProvider = process.env.DFX_NETWORK === 'ic' ?
                            'https://identity.ic0.app' // Mainnet
                            : `http://${identityCanisterID}.localhost:4943/`; // Local
let authClient = await AuthClient.create();
let identity = authClient.getIdentity();

export let actor =  createActor(backendCanisterID, {
                        agentOptions: {
                            identity
                        }
                    });

export let isAuthenticated: boolean = await authClient.isAuthenticated();

export const updateActor = async () => {
    identity = authClient.getIdentity();
    actor = createActor(backendCanisterID, {
      agentOptions: {
        identity
      }
    });
    
    isAuthenticated = await authClient.isAuthenticated();
}

export const login = async () => {
    await authClient.login({
        identityProvider,
        onSuccess: () => {
            updateActor();
            window.location.reload();
        }
    });
};

export const logout = async () => {
    await authClient.logout()
    window.location.reload();
};