import Map "mo:core/Map";
import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Array "mo:core/Array";
import Time "mo:core/Time";
import UserData "../models/todosUserData";
import Identifiers "../shared/identifiers";
import MixinDefineCoordinatorActor "mixins/mixinDefineCoordinatorActor";
import MixinTopCanister "mixins/mixinTopCanister";
import MixinAllowedCanisters "mixins/mixinAllowedCanisters";
import Errors "../shared/errors";
import { setTimer; recurringTimer } = "mo:core/Timer";

shared ({ caller = owner }) persistent actor class UsersBucket() = this {
    /////////////
    // CONFIGS //
    /////////////

    let TOPPING_THRESHOLD   = 1_000_000_000_000;
    let TOPPING_AMOUNT      = 2_000_000_000_000;
    let TOPPING_INTERVAL    = 20_000_000_000;
    let MAX_NUMBER_ENTRIES  = 1_000_000;

    ////////////
    // MIXINS //
    ////////////

    include MixinDefineCoordinatorActor(owner);
    include MixinTopCanister(coordinatorActor, Principal.fromActor(this), TOPPING_THRESHOLD, TOPPING_AMOUNT);
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
            ignore recurringTimer<system>(#seconds(TOPPING_INTERVAL), topCanisterRequest);
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
        let ?userData = memoryUsers.get(caller) else return #err(Errors.ERR_USER_NOT_FOUND);

        #ok({
            name = userData.name;
            email = userData.email;
            groups = Array.fromIter( Map.keys(userData.groups) );
            createdAt = userData.createdAt;
        })
    };

    public shared func handlerCreateUser({ userPrincipal: Principal; }) : async Result.Result<(), Text> {
        switch ( memoryUsers.get(userPrincipal) ) {
            case (?_) return #err(Errors.ERR_USER_ALREADY_EXISTS);
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