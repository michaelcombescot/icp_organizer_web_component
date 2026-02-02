import Map "mo:core/Map";
import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Array "mo:core/Array";
import Time "mo:core/Time";
import UserData "../models/userData";
import Identifiers "../../../shared/identifiers";
import MixinOpsOperations "../../../shared/mixins/mixinOpsOperations";
import MixinAllowedCanisters "../../../shared/mixins/mixinAllowedCanisters";
import Timer "mo:core/Timer";
import Errors "../../../shared/errors";

// This kind of bucket exists to map a user principal with the principal of the bucket where it's data are stored.
// This is done in the goal to have an easy distribution among users between exixsting buckets in a predictable way and smooth out the scaling if needed.
shared ({ caller = owner }) persistent actor class UsersBucket() = this {
    ////////////
    // MIXINS //
    ////////////

    include MixinOpsOperations({
        coordinatorPrincipal    = owner;
        canisterPrincipal       = Principal.fromActor(this);
        toppingThreshold        = 2_000_000_000_000;
        toppingAmount           = 2_000_000_000_000;
        toppingIntervalNs       = 20_000_000_000;
    });
    include MixinAllowedCanisters(coordinatorActor);

    ////////////
    // MEMORY //
    ////////////

    let memoryUsers = Map.empty<Principal, Principal>();

    //////////
    // JOBS //
    //////////

    ignore Timer.setTimer<system>(
        #seconds(0),
        func () : async () {
            ignore Timer.recurringTimer<system>(#seconds(60_000_000_000), topCanisterRequest);
            await topCanisterRequest();
        }
    );

    ////////////
    // SYSTEM //
    ////////////

    type InspectParams = {
        arg: Blob;
        caller : Principal;
        msg : {
            #handlerGetUserDataBucket : () -> ();
            #handlerCreateUser : () -> (userPrincipal : Principal, userBucketPrincipal : Principal);
        }
    };

    system func inspect(params: InspectParams) : Bool {
        if ( params.caller == Principal.anonymous() ) { return false; };

        switch ( params.msg ) {
            case (#handlerGetUserDataBucket(_))     true;
            case (#handlerCreateUser(_))            true;
        }
    };



    /////////
    // API //
    /////////

    public shared ({ caller }) func handlerGetUserDataBucket() : async Result.Result<Principal, Text> {
        let ?userBucket = memoryUsers.get(caller) else return #err(Errors.ERR_USER_DOES_NOT_EXISTS);
        #ok(userBucket);
    };

    public shared func handlerCreateUser(userPrincipal: Principal, userBucketPrincipal: Principal) : async Result.Result<(), Text> {
        let ?_ = memoryUsers.get(userPrincipal) else return #err(Errors.ERR_USER_ALREADY_EXISTS);
        memoryUsers.add(userPrincipal, userBucketPrincipal);
        #ok();
    };
};