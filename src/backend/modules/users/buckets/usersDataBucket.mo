import MixinOpsOperations "../../../shared/mixins/mixinOpsOperations";
import MixinAllowedCanisters "../../../shared/mixins/mixinAllowedCanisters";
import { setTimer; recurringTimer } = "mo:core/Timer";
import Map "mo:core/Map";
import Principal "mo:core/Principal";
import Blob "mo:core/Blob";
import Result "mo:core/Result";
import UserData "../models/userData";
import Errors "../../../shared/errors";

shared ({ caller = owner }) persistent actor class UsersDataBucket() = this {
    /////////////
    // CONFIGS //
    /////////////

    let MAX_NUMBER_ENTRIES  = 100_000_000;

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

    let memory = {
        users = Map.empty<Principal, UserData.UserData>();
        idUserCounter = 0;
    };

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
    // SYSTEM //
    ////////////

    type InspectParams = {
        arg: Blob;
        caller : Principal;
        msg : {
            #createUserData : () -> (userPrincipal : Principal);
            #getUserData: () -> (userPrincipal: Principal);
        };
    };

    system func inspect(params: InspectParams) : Bool {
        if ( params.caller == Principal.anonymous() ) { return false; };

        if ( Blob.size(params.arg) > 50 ) { return false; };

        switch ( params.msg ) {
            case (#createUserData(_)) params.caller == owner;
            case (#getUserData(_)) params.caller == owner;
        }
    };

    /////////
    // API //
    /////////

    public shared func createUserData(userPrincipal: Principal) : async Result.Result<(), Text> {
        if ( Map.size(memory.users) >= MAX_NUMBER_ENTRIES ) { return #err(Errors.ERR_BUCKET_FULL); };

        switch ( Map.get(memory.users, userPrincipal) ) {
            case null {
                Map.add(memory.users, userPrincipal, UserData.newUserData());
                #ok(());
            };
            case (?_) #err(Errors.ERR_USER_ALREADY_EXISTS);
        }
    };

    public shared func getUserData(userPrincipal: Principal) : async Result.Result<UserData.SharableUserData, Text> {
        switch ( Map.get(memory.users, userPrincipal) ) {
            case null #err("User not found");
            case (?userData) #ok( UserData.newSharableUserData(userData) );
        }
    };
}