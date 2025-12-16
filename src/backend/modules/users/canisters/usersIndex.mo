import CanistersMap "../../../shared/canistersMap";
import Principal "mo:core/Principal";
import Nat32 "mo:core/Nat32";
import Result "mo:core/Result";
import CanistersKinds "../../../shared/canistersKinds";
import UsersBucket "usersBucket";

shared ({ caller = owner }) persistent actor class UsersIndex() = this {
    ////////////
    // MEMORY //
    ////////////

    let memoryCanisters = CanistersMap.newCanisterMap();

    var memoryUsersMapping: [Principal] = [];

    ////////////
    // SYSTEM //
    ////////////

    type InspectParams = {
        arg: Blob;
        caller : Principal;
        msg : {
            #systemAddCanistersToMap : () -> { canistersPrincipals: [Principal]; canisterKind: CanistersKinds.CanisterKind };
            #systemUpdateUsersMapping : () -> (usersMapping: [Principal]);

            #handlerFetchUserBucket : () -> ();
            #createUser : () -> ();
        }
    };

    system func inspect(params: InspectParams) : Bool {
        if ( params.caller == Principal.anonymous() ) { return false; };

        switch ( params.msg ) {
            case (#systemAddCanistersToMap(_))       params.caller == owner;
            case (#systemUpdateUsersMapping(_))      params.caller == owner;

            case (#handlerFetchUserBucket(_))        true;
            case (#createUser(_))                    true;
        }
    };

    public shared func systemAddCanistersToMap({ canistersPrincipals: [Principal]; canisterKind: CanistersKinds.CanisterKind }) : async () {
        CanistersMap.addCanistersToMap({ map = memoryCanisters; canistersPrincipals = canistersPrincipals; canisterKind = canisterKind });
    };

    public shared func systemUpdateUsersMapping(usersMapping: [Principal]) : async () {
        memoryUsersMapping := usersMapping;
    };

    /////////
    // API //
    /////////

    public query ({ caller }) func handlerFetchUserBucket() : async Principal {
        helperFetchUserBucket(caller)
    };

    public shared ({ caller }) func createUser() : async Result.Result<Principal, Text> {
        let bucketPrincipal = helperFetchUserBucket(caller);

        switch ( await (actor(Principal.toText(bucketPrincipal)): UsersBucket.UsersBucket).handlerCreateUser({ userPrincipal = caller }) ) {
            case (#ok()) #ok(bucketPrincipal);
            case (#err(e)) #err(e);
        }
    };

    /////////////
    // HELPERS //
    /////////////

    func helperFetchUserBucket(userPrincipal: Principal) : Principal {
        let userPrincipalHash = Principal.hash(userPrincipal);
        memoryUsersMapping[ Nat32.toNat(userPrincipalHash) % memoryUsersMapping.size()]
    };
};