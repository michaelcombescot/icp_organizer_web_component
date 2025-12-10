import { AuthClient } from '@dfinity/auth-client';
import { canisterId as identityCanisterID } from '../../../../declarations/internet_identity/index';

const identityProvider = process.env.DFX_NETWORK === 'ic' ?
                            'https://identity.ic0.app' // Mainnet
                            : `http://${identityCanisterID}.localhost:4943/`; // Local

let authClient = await AuthClient.create();

export let identity = authClient.getIdentity();

export let isAuthenticated: boolean = await authClient.isAuthenticated();

export const login = async () => {
    await authClient.login({
        identityProvider,
        onSuccess: async () => {
            identity        = authClient.getIdentity();
            isAuthenticated = await authClient.isAuthenticated();

            window.location.reload();
        }
    });
};

export const logout = async () => {
    await authClient.logout()
    window.location.reload();
};