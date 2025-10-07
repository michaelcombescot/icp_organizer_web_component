import Text "mo:base/Text";
import Map "mo:core/Map";
import Result "mo:core/Result";
import Principal "mo:core/Principal";
import Nat "mo:core/Nat";
import OrderedMap "mo:base/OrderedMap";
import UsersDataBucket "./usersDataBucket";
import Interfaces "../../shared/interfaces";
import Debug "mo:core/Debug";
import Error "mo:core/Error";
import Configs "../../shared/configs";
import Errors "../../shared/errors";

type BucketData = {
    principal: Principal;
    bucket: UsersDataBucket.UsersDataBucket;
    nbEntries: Nat;
};

// This actor is in charge to map a principal with a bucket containing the user data
shared ({ caller = owner }) persistent actor class UsersDataIndex() = this {
    //
    // MEMORY
    //

    transient let bucketMapOperations = OrderedMap.Make<Principal>(Principal.compare);
    var bucketsStore = bucketMapOperations.empty<BucketData>();

    var principalsOnBuckets = Map.empty<Principal, Principal>();

    //
    // API 
    //

    public shared ({ caller }) func getOrCreateBucket() : async Result.Result<Principal, Text> {
        if ( Principal.isAnonymous(caller) ) { return #err(Errors.ERR_NOT_CONNECTED); };

        // if no user entry, create one in the current bucket (last entry of the ordered map).
        // if there is no last entry, or the last entry if full, create a new entry
        switch ( Map.get(principalsOnBuckets, Principal.compare, caller) ) {
            case (?bucketPrincipal) return #ok(bucketPrincipal);
            case null {
                switch (bucketMapOperations.maxEntry(bucketsStore)) {
                    case (?(bucketPrincipal, bucket)) {
                        if (bucket.nbEntries < Configs.Consts.BUCKET_USERS_DATA_MAX_ENTRIES) {
                            addUserToBucket(bucketPrincipal, caller);
                            return #ok(bucketPrincipal);
                        } else {
                            let bucket = await createBucket();
                            addUserToBucket(bucketPrincipal, bucketPrincipal);
                            return #ok(bucketPrincipal);
                        };
                    };
                    case null {
                        let newBucketPrincipal = await createBucket();
                        addUserToBucket(newBucketPrincipal, caller);
                        return #ok(newBucketPrincipal);
                    };
                };
            };
        };
    };

    

    func addUserToBucket(bucketPrincipal: Principal, caller: Principal) : () {
        Map.add(principalsOnBuckets, Principal.compare, caller, bucketPrincipal);
    };
};

