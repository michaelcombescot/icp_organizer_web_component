import Principal "mo:core/Principal";
import Debug "mo:core/Debug";
import Result "mo:core/Result";
import Error "mo:core/Error";
import Text "mo:core/Text";
import OrderedMap "mo:base/OrderedMap";
import Interfaces "../../shared/interfaces";
import Configs "../../shared/configs";
import Errors "../../shared/errors";
import Group "groupModel";
import GroupsBucket "groupsBucket";
import Time "mo:core/Time";

shared ({ caller = owner }) persistent actor class TodosIndex() = this {
    type BucketData = {
        createdAt: Time.Time;
        aktor: GroupsBucket.GroupsBucket;
    };

    transient let bucketMapOperations = OrderedMap.Make<Principal>(Principal.compare);
    var bucketsStore = bucketMapOperations.empty<BucketData>();

    //
    // API 
    //

    // create a new todo in the last created bucket.
    // trigger the creation of a new bucket if the last one is full
    // return the id of the created todo
    public shared ({ caller }) func createTodo(param: Group.CreateGroupParam) : async Result.Result<Text, [Text]> {
        if ( caller == Principal.anonymous() ) { return #err([Errors.ERR_NOT_CONNECTED]); };

        if (bucketsStore.size == 0) { await createNewBucket(); };

        switch ( bucketMapOperations.maxEntry(bucketsStore) ) {
            case (?(_, bucketData)) {
                switch ( await bucketData.aktor.createGroup(param) ) {
                    case (#ok(id, nbEntries)) {
                        if ( nbEntries > Configs.Consts.BUCKET_TODOS_MAX_ENTRIES ) {
                            await createNewBucket();
                        };

                        return #ok(id);
                    };
                    case (#err(e)) return #err(e);
                };
            };
            case (null) return #err([Errors.ERR_NO_BUCKET_FOUND]);
        }
    };

    //
    // PRIVATE
    //

    // create a new bucket and update the bucket store
    // it should not be necessary to do more than that to have something fiable, because even if one creation failed, next one will probably succeed.
    // only risk is to have too many todos in a single specific bucket but it should almost never happened
    func createNewBucket() : async () {
        try {
            switch ( await Interfaces.MaintenanceIndex.canister.addBucket() ) {
                case (#ok(bucketPrincipal)) bucketsStore := bucketMapOperations.put(
                                                                                    bucketsStore,
                                                                                    bucketPrincipal,
                                                                                    { createdAt = Time.now(); aktor = actor (Principal.toText(bucketPrincipal)) : GroupsBucket.GroupsBucket; }
                                                                                );
                case (#err(e)) Debug.print("Cannot create new bucket: " # e);
            };
        } catch (e) {
            Debug.print("Cannot create new bucket: " # Error.message(e));
        };
    };
}