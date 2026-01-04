import { SharableUserData } from "../../../../../declarations/usersBucket/usersBucket.did";
import { Actors } from "../actors/actors";
import { Principal } from "@dfinity/principal";

export class StoreUser {
    static userData: SharableUserData

    static async fetchUserData() {
        let res = await Actors.createUserBucketActor().handlerGetUserData()

        if ("err" in res) {
            console.log("cannot fetch user data", res.err)
            return
        }

        this.userData = res.ok
    }
}