import { SharableUserData } from "../../../../../declarations/usersBucket/usersBucket.did";
import { Actors } from "../../../actors/actors";
import { StoreGroups } from "./storeGroups";

export class StoreUser {
    static userData: SharableUserData

    static async fetchUserData() {
        let res = await Actors.createUserBucketActor().handlerGetUserData()

        if ("err" in res) {
            console.error("cannot fetch user data", res.err)
            return
        }

        this.userData = res.ok

        if (StoreGroups.groupsData.size === 0) {
            await Actors.getMainIndex().handlerCreateGroup({ name: "Personnal", kind: { 'personnal' : null }});
        }
    }
}