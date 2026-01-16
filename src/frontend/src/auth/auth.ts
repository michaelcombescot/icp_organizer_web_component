import { AuthClient } from '@dfinity/auth-client';
import { canisterId as identityCanisterID } from '../../../declarations/internet_identity/index';
import { Actors } from '../actors/actors';
import { getLoadingComponent } from "../components/loading"
import { StoreUser } from '../modules/todo/stores/storeUser';
import { getMainApp } from '../App';
import { navigateTo, routes } from '../components/router/router';

const identityProvider = process.env.DFX_NETWORK === 'ic' ?
                            'https://identity.ic0.app' // Mainnet
                            : `http://${identityCanisterID}.localhost:4943/`; // Local

let authClient = await AuthClient.create();

export let identity = authClient.getIdentity();

export let isAuthenticated: boolean = await authClient.isAuthenticated();

export const login = async () => {
    getLoadingComponent().wrapAsync(async () => {
        await new Promise<void>((resolve, reject) => {
            authClient.login({
                identityProvider,
                onSuccess: async () => {
                    try {
                        identity = authClient.getIdentity();
                        isAuthenticated = await authClient.isAuthenticated();

                        await Actors.fetchIndexes()
                        await Actors.fetchUserBucket();        
                        
                        getMainApp().render()
                        navigateTo(routes.home)

                        resolve();
                    } catch (e) {
                        reject(e); 
                    }
                },
                onError: (err) => {
                    console.error("Login failed", err);
                    reject(err);
                }
            });
        });
    })
};

export const logout = async () => {
    await authClient.logout()
    sessionStorage.removeItem(Actors.SESSION_STORAGE_USER_BUCKET_KEY)
    window.location.reload();
};