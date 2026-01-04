import Map "mo:core/Map";
import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Array "mo:core/Array";
import Time "mo:core/Time";
import UserData "../models/todosUserData";
import Identifiers "../shared/identifiers";
import Interfaces "../shared/interfaces";
import MixinAllowedCanisters "mixins/mixinAllowedCanisters";
import Errors "../shared/errors"

shared ({ caller = owner }) persistent actor class UsersBucket() = this {
    include MixinAllowedCanisters(owner);

    /////////////
    // CONFIGS //
    /////////////

    let MAX_NUMBER_ENTRIES = 10_000_000; // TODO handle max number entries in handlerCreateUser    

    ////////////
    // MEMORY //
    ////////////

    let memoryUsers = Map.empty<Principal, UserData.UserData>();

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