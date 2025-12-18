import { APIRegistry } from "./apiRegistry"

export class APIMainIndex {
    static async createUser() : Promise<void> {
        let res = await APIRegistry.getMainIndex().handlerFetchOrCreateUser()
        if ('err' in res) { console.error(res.err) }
    }
}