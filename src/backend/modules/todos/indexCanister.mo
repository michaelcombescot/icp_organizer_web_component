import Text "mo:base/Text";
import Map "mo:core/Map";
import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Option "mo:base/Option";
import MapCore "mo:core/Map";
import Array "mo:core/Array";
import Nat "mo:core/Nat";
import Nat32 "mo:core/Nat32";
import Cycles "mo:base/ExperimentalCycles";
import BucketUsers "./buckets/bucket_users";
import BucketUsersMapping "./buckets/bucketUsersMapping";
import Model "model_todo";

persistent actor {
    let NEW_BUCKET_NB_CYCLES = 1_000_000_000;
    
    //
    // BUCKETS
    //

    let BUCKET_USERS_DATA_MAX_ENTRIES = 10_000;
    var bucketUsersData =  { bucketIndex = 0; nbUsers = 0; };
    var bucketUsers     = Map.empty<Nat, BucketUsers.BucketUsers>();

    //
    // MAPPINGS
    //

    let principalsOnBuckets = Map.empty<Principal, Nat>();

    //
    // INC
    //

    var lastTodoId = 0;
    var lastTodoListId = 0;

    //
    // USER 
    //

    // call this function when a user connect, create the bucket for the user if it doesn't exist
    public shared ({ caller }) func login() : async Result.Result<(), Text> {
        if ( Principal.isAnonymous(caller) ) { return #err("Not logged in"); };

        if (Option.isSome( Map.get(principalsOnBuckets, Principal.compare, caller) )) { return #ok; };

        if ( bucketUsersData.bucketIndex == 0 or bucketUsersData.nbUsers >= BUCKET_USERS_DATA_MAX_ENTRIES ) { // create a new bucket
            let bucket = await BucketUsers.BucketUsers({ _cycles = NEW_BUCKET_NB_CYCLES });
            bucketUsersData := { bucketIndex = bucketUsersData.bucketIndex + 1; nbUsers = 0; };
            Map.add(bucketUsers, Nat.compare, bucketUsersData.bucketIndex, bucket);
        };

        Map.add( principalsOnBuckets, Principal.compare, caller, bucketUsersData.bucketIndex );

        let ?bucket = Map.get(bucketUsers, Nat.compare, bucketUsersData.bucketIndex) else return #err("No bucket");

        switch ( await bucket.createUserData(caller) ) {
            case (#ok) #ok;
            case (#err err) #err(err);
        }
    };
};

