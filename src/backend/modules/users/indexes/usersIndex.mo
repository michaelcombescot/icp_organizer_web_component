import MixinAllowedCanisters "../../../shared/mixins/mixinAllowedCanisters";
import MixinOpsOperations "../../../shared/mixins/mixinOpsOperations";
import Principal "mo:core/Principal";
import Timer "mo:core/Timer";
import Blob "mo:core/Blob";
import UsersMapping "../helpers/usersMapping";
import UsersBucket "../buckets/usersBucket";

shared ({ caller = owner }) persistent actor class UsersIndex() = this {
    /////////////
    // CONFIGS //
    /////////////

    ////////////
    // MIXINS //
    ////////////

    include MixinOpsOperations({
        coordinatorPrincipal    = owner;
        canisterPrincipal       = Principal.fromActor(this);
        toppingThreshold        = 2_000_000_000_000;
        toppingAmount           = 2_000_000_000_000;
        toppingIntervalNs       = 60_000_000_000;
    });
    include MixinAllowedCanisters(coordinatorActor); 

    ////////////
    // MEMORY //
    ////////////

    let memory = {
        memoryUsersMapping: [Principal] = [];
    };

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
            #getCurrentUserData: () -> ();
        };
    };

    system func inspect(params: InspectParams) : Bool {
        if ( params.caller == Principal.anonymous() ) { return false; };

        if ( Blob.size(params.arg) > 50 ) { return false; };

        switch ( params.msg ) {
            case (#getCurrentUserData(_)) true;
        }
    };

    /////////
    // API //
    /////////

    public shared ({ caller }) func getCurrentUserData() : async Principal {
        let userBucketPrincipal = UsersMapping.helperFetchUserBucket(memoryUsersMapping, caller);

        switch ( (actor(userBucketPrincipal): UsersBucket.UsersBucket).getUserPrincipal() ) {
            case ( null ) {
                // this should never happen due to the inspect function
                throw Error.reject("ERR_INVALID_CALLER");
            };
            case ( some bucketActor ) {
                return await bucketActor.getUserPrincipal(caller);
            };
        }
    };
}