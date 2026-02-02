import MixinAllowedCanisters "../../../shared/mixins/mixinAllowedCanisters";
import MixinOpsOperations "../../../shared/mixins/mixinOpsOperations";
import Principal "mo:core/Principal";
import Timer "mo:core/Timer";
import Blob "mo:core/Blob";
import Result "mo:core/Result";
import UsersMapping "../helpers/usersMapping";
import UsersBucket "../buckets/usersBucket";
import UsersDataBucket "../buckets/usersDataBucket";
import UserData "../models/userData";

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
        usersArray: [Principal] = [];
        currentDataBucket: ?Principal = null
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
            #createUser : () -> ();
            #getUserData: () -> ();
        };
    };

    system func inspect(params: InspectParams) : Bool {
        if ( params.caller == Principal.anonymous() ) { return false; };

        if ( Blob.size(params.arg) > 50 ) { return false; };

        switch ( params.msg ) {
            case (#createUser(_)) true;
            case (#getUserData(_)) true;
        }
    };

    /////////
    // API //
    /////////

    public shared ({ caller }) func createUser() : async Result.Result<Principal, Text> {
        let userBucketPrincipal = UsersMapping.helperFetchUserBucket(memory.usersArray, caller);

        switch ( await (actor(userBucketPrincipal.toText()): UsersBucket.UsersBucket).handlerCreateUser(caller, userBucketPrincipal) ) {
            case ( #ok(_) ) ;
            case ( #err(error)) return #err(error);
        };

        switch ( await (actor(userBucketPrincipal.toText()): UsersBucket.UsersBucket).handlerCreateUser(caller) ) {
            case ( #ok(dataPrincipal) ) dataPrincipal;      
            case ( #err(error)) return #err(error);
        };
    };

    public shared ({ caller }) func getUserData() : async Result.Result<UserData.SharableUserData, Text> {
        let userBucketPrincipal = UsersMapping.helperFetchUserBucket(memory.usersArray, caller);

        let userDataPrincipal = switch ( await (actor(userBucketPrincipal.toText()): UsersBucket.UsersBucket).handlerGetUserDataBucket() ) {
                                    case ( #ok(dataPrincipal) ) dataPrincipal;      
                                    case ( #err(error)) return #err(error);
                                };

        await (actor(userDataPrincipal.toText()): UsersDataBucket.UsersDataBucket).getUserData(caller)
    };
}