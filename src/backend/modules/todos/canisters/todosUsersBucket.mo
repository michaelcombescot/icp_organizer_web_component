import Map "mo:core/Map";
import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Array "mo:core/Array";
import Time "mo:core/Time";
import Option "mo:core/Option";
import UserData "../models/todosUserData";
import CanistersMap "../../../shared/canistersMap";
import CanistersKinds "../../../shared/canistersKinds";
import Identifiers "../../../shared/identifiers";

shared ({ caller = owner }) persistent actor class TodosUsersBucket() = this {
    /////////////
    // CONFIGS //
    /////////////

    let MAX_NUMBER_ENTRIES = 100_000_000; // TODO handle max number entries in handlerCreateUser

    ////////////
    // ERRORS //
    ////////////

    let ERR_USER_NOT_FOUND = "ERR_USER_NOT_FOUND";
    let ERR_USER_ALREADY_EXISTS = "ERR_USER_ALREADY_EXISTS";

    ////////////
    // MEMORY //
    ////////////

    let memoryUsers = Map.empty<Principal, UserData.UserData>();

    let memoryCanisters = CanistersMap.newCanisterMap();

    ////////////
    // SYSTEM //
    ////////////

    type InspectParams = {
        arg: Blob;
        caller : Principal;
        msg : {
            #systemAddCanistersToMap : () -> { canistersPrincipals: [Principal]; canisterKind: CanistersKinds.CanisterKind };

            #handlerGetUserData : () -> (userPrincipal: Principal);
            #handlerCreateUser : () -> { userPrincipal: Principal; groupIdentifier: Identifiers.Identifier };
        }
    };

    system func inspect(params: InspectParams) : Bool {
        if ( params.caller == Principal.anonymous() ) { return false; };

        switch ( params.msg ) {
            case (#systemAddCanistersToMap(_))  CanistersMap.isPrincipalInKind(memoryCanisters, params.caller, #todosIndex);

            case (#handlerGetUserData(_))       Option.isSome(Map.get(memoryUsers, Principal.compare, params.caller));
            case (#handlerCreateUser(_))        CanistersMap.isPrincipalInKind(memoryCanisters, params.caller, #todosIndex);
        }
    };

    public shared func systemAddCanistersToMap({ canistersPrincipals: [Principal]; canisterKind: CanistersKinds.CanisterKind }) : async () {
        CanistersMap.addCanistersToMap({ map = memoryCanisters; canistersPrincipals = canistersPrincipals; canisterKind = canisterKind });
    };

    /////////
    // API //
    /////////

    public shared func handlerGetUserData( userPrincipal: Principal ) : async Result.Result<UserData.SharableUserData, Text> {
        let ?userData = Map.get(memoryUsers, Principal.compare, userPrincipal) else return #err(ERR_USER_NOT_FOUND);

        #ok({
            name = userData.name;
            email = userData.email;
            groups = Array.fromIter( Map.keys(userData.groups) );
            createdAt = userData.createdAt;
        })
    };

    public shared func handlerCreateUser({ userPrincipal: Principal; groupIdentifier: Identifiers.Identifier }) : async Result.Result<(), Text> {
        switch ( Map.get(memoryUsers, Principal.compare, userPrincipal) ) {
            case (?_) return #err(ERR_USER_ALREADY_EXISTS);
            case null ();
        };

        // create user data
        let userData: UserData.UserData = {
            name = "";
            email = "";
            groups = Map.singleton<Identifiers.Identifier, ()>(groupIdentifier, () );
            createdAt = Time.now();
        };

        Map.add(memoryUsers, Principal.compare, userPrincipal, userData);

        #ok();
    };
};