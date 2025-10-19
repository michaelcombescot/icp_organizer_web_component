import Text "mo:base/Text";
import Map "mo:core/Map";
import Result "mo:core/Result";
import Principal "mo:core/Principal";
import Nat "mo:core/Nat";
import OrderedMap "mo:base/OrderedMap";
import Interfaces "../../shared/interfaces";
import Debug "mo:core/Debug";
import Error "mo:core/Error";
import Configs "../../shared/configs";
import Errors "../../shared/errors";

// This actor is in charge to map a principal with a bucket containing the user data
shared ({ caller = owner }) persistent actor class UsersDataIndex() = this {
    type BucketData = {
        principal: Principal;
        nbEntries: Nat;
    };

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

        var mustCreateBucket = false;
        var respBucketPrincipal = Principal.anonymous();
        
        switch ( Map.get(principalsOnBuckets, Principal.compare, caller) ) {
            case (?bucketPrincipal) return #ok(bucketPrincipal);
            case null {
                switch (bucketMapOperations.maxEntry(bucketsStore)) {
                    case (?(bucketPrincipal, bucket)) {
                        if (bucket.nbEntries <= Configs.Consts.BUCKET_USERS_DATA_MAX_ENTRIES) {
                            respBucketPrincipal := bucketPrincipal;
                        } else {
                            mustCreateBucket := true;
                        };
                    };
                    case null {
                        mustCreateBucket := true
                    };
                };
            };
        };

        if (mustCreateBucket) {
            try {
                switch ( await Interfaces.MaintenanceIndex.canister.addBucket() ) {
                    case (#ok(bucketPrincipal)) {
                        respBucketPrincipal := bucketPrincipal;

                        bucketsStore := bucketMapOperations.put(bucketsStore, respBucketPrincipal, { principal = respBucketPrincipal; nbEntries = 1; });
                    };
                    case (#err(e)) {
                        Debug.print("Cannot create new bucket: " # e);
                        return #err("Cannot create new bucket");
                    }
                };
            } catch (e) {
                Debug.print("Cannot create new bucket: " # Error.message(e));
                return #err("Cannot create new bucket");
            }
        };

        Map.add(principalsOnBuckets, Principal.compare, caller, respBucketPrincipal);

        #ok(respBucketPrincipal)
    };
};

