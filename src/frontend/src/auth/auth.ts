import { AuthClient } from '@dfinity/auth-client';
import { canisterId as identityCanisterID } from '../../../declarations/internet_identity/index';
import { Actors } from '../modules/todo/actors/actors';
import { Identity } from '@dfinity/agent';
import { getLoadingComponent } from "../components/loading"

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
                // 2. Resolve the promise ONLY when success happens
                onSuccess: async () => {
                    try {
                        identity = authClient.getIdentity();
                        isAuthenticated = await authClient.isAuthenticated();

                        await Actors.fetchIndexes();
                        await Actors.getMainIndex().handlerFetchOrCreateUser();
                        
                        window.location.reload();
                        resolve(); // <--- This tells the wrapper "We are done"
                    } catch (e) {
                        reject(e); // Handle errors inside the async callback
                    }
                },
                // 3. Don't forget to handle errors/cancellation!
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
    window.location.reload();
};