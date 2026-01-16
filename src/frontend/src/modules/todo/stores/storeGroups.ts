import { Principal } from "@dfinity/principal";
import { Identifier, RespGetGroupDisplayData } from "../../../../../declarations/groupsBucket/groupsBucket.did";
import { Actors } from "../../../actors/actors";

export class StoreGroups {
    static groupsData = new Map<Identifier, RespGetGroupDisplayData>();

    static async getGroupDisplayData (groupidentifier: Identifier) {
        let res = await Actors.createGroupsBucketActor(groupidentifier.bucket).handlerGetGroupDisplayData(groupidentifier.id)
        if ("err" in res) {
            console.error(res.err)
            return
        }

        this.groupsData.set(groupidentifier, res.ok)
    }
}