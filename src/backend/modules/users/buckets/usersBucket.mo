import Map "mo:core/Map";
import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Array "mo:core/Array";
import Time "mo:core/Time";
import UserData "../models/userData";
import Identifiers "../../../shared/identifiers";
import MixinOpsOperations "../../../shared/mixins/mixinOpsOperations";
import MixinAllowedCanisters "../../../shared/mixins/mixinAllowedCanisters";
import { setTimer; recurringTimer } = "mo:core/Timer";

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

    let memoryUsers = Map.empty<Principal, UserData.UserData>();

    //////////
    // JOBS //
    //////////

    ignore setTimer<system>(
        #seconds(0),
        func () : async () {
            ignore recurringTimer<system>(#seconds(60_000_000_000), topCanisterRequest);
            await topCanisterRequest();
        }
    );

    ////////////
    // ERRORS //
    ////////////

    let ERR_USER_NOT_FOUND = "ERR_USER_NOT_FOUND";
    let ERR_USER_ALREADY_EXISTS = "ERR_USER_ALREADY_EXISTS";

    ////////////
    // SYSTEM //
    ////////////

    type InspectParams = {
        arg: Blob;
        caller : Principal;
        msg : {
            #handlerGetUserData : () -> ();
            #handlerCreateUser : () -> { userPrincipal: Principal; };
        }
    };

    system func inspect(params: InspectParams) : Bool {
        if ( params.caller == Principal.anonymous() ) { return false; };

        switch ( params.msg ) {
            case (#handlerGetUserData(_))       true;
            case (#handlerCreateUser(_))        true;
        }
    };



    /////////
    // API //
    /////////

    public shared ({ caller }) func handlerGetUserData() : async Result.Result<UserData.SharableUserData, Text> {
        let ?userData = memoryUsers.get(caller) else return #err(ERR_USER_NOT_FOUND);

        #ok({
            name = userData.name;
            email = userData.email;
            groups = Array.fromIter( Map.keys(userData.groups) );
            createdAt = userData.createdAt;
        })
    };

    public shared func handlerCreateUser({ userPrincipal: Principal; }) : async Result.Result<(), Text> {
        switch ( memoryUsers.get(userPrincipal) ) {
            case (?_) return #err(ERR_USER_ALREADY_EXISTS);
            case null ();
        };

        // create user data
        let userData: UserData.UserData = {
            name = "";
            email = "";
            groups = Map.empty<Identifiers.Identifier, ()>();
            createdAt = Time.now();
        };

        memoryUsers.add(userPrincipal, userData);

        #ok();
    };
};