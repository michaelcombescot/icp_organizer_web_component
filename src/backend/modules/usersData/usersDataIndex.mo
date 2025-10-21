import Text "mo:base/Text";
import Map "mo:core/Map";
import Result "mo:core/Result";
import Principal "mo:core/Principal";
import OrderedMap "mo:base/OrderedMap";
import Interfaces "../../shared/interfaces";
import Debug "mo:core/Debug";
import Error "mo:core/Error";
import Configs "../../shared/configs";
import Errors "../../shared/errors";
import UsersDataBucket "usersDataBucket";

// This actor is in charge to map a principal with a bucket containing the user data
shared ({ caller = owner }) persistent actor class UsersDataIndex() = this {
    //
    // MEMORY
    //

    transient let bucketMapOperations = OrderedMap.Make<Principal>(Principal.compare);
    var bucketsStore = bucketMapOperations.empty<UsersDataBucket.UsersDataBucket>();

    var principalsOnBuckets = Map.empty<Principal, Principal>();

    //
    // API 
    //

    public shared ({ caller }) func getOrCreateBucket() : async Result.Result<Principal, [Text]> {
        if ( caller == Principal.anonymous() ) { return #err([Errors.ERR_NOT_CONNECTED]); };

        if (bucketsStore.size == 0) { await createNewBucket(); };

        switch ( bucketMapOperations.maxEntry(bucketsStore) ) {
            case (?(_, bucketAktor)) {
                switch ( await bucketAktor.createUserData(caller) ) {
                    case (#ok(nbEntries)) {
                        if ( nbEntries > Configs.Consts.BUCKET_USERS_DATA_MAX_ENTRIES ) {
                            await createNewBucket();
                        };

                        Map.add(principalsOnBuckets, Principal.compare, caller, Principal.fromActor(bucketAktor));

                        return #ok(Principal.fromActor(bucketAktor));
                    };
                    case (#err(e)) return #err([e]);
                };
            };
            case (null) return #err([Errors.ERR_NO_BUCKET_FOUND]);
        }
    };

    //
    // HELPERS
    //

    func createNewBucket() : async () {
        try {
            switch ( await Interfaces.MaintenanceIndex.canister.addBucket() ) {
                case (#ok(bucketPrincipal)) bucketsStore := bucketMapOperations.put(bucketsStore, bucketPrincipal, actor (Principal.toText(bucketPrincipal)) : UsersDataBucket.UsersDataBucket);
                case (#err(e)) Debug.print("Cannot create new bucket: " # e);
            };
        } catch (e) {
            Debug.print("Cannot create new bucket: " # Error.message(e));
        };
    };
};

