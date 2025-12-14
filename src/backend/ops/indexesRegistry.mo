import Principal "mo:core/Principal";
import Blob "mo:core/Blob";
import CanistersKinds "../shared/canistersKinds";
import CanistersMap "../shared/canistersMap";

// only goal of this canister is too keep track of all the indexes and serve their principal to the frontend.
// not dynamically created, if the need arise another instance will need to be declared in the dfx.json
shared ({ caller = owner }) persistent actor class IndexesRegistry() = this {
    
    ////////////
    // MEMORY //
    ////////////

    let memoryCanisters = CanistersMap.newCanisterMap();

    var coordinatorPrincipal : ?Principal = null;

    ////////////
    // SYSTEM //
    ////////////

    type InspectParams = {
        arg: Blob;
        caller : Principal;
        msg : {
            #systemAddCanistersToMap : () -> { canistersPrincipals: [Principal]; canisterKind: CanistersKinds.CanisterKind };
            #systemSetCoordinator : () -> {coordinatorPrincipalArg : Principal};

            #handlerGetIndexes : () -> (kind: CanistersKinds.Indexes);
        };
    };

    system func inspect(params: InspectParams) : Bool {
        if ( params.caller == Principal.anonymous() ) { return false; };

        if ( Blob.size(params.arg) > 10 ) { return false; };

        switch ( params.msg ) {
            case (#systemAddCanistersToMap(_))  ?params.caller == coordinatorPrincipal;
            case (#systemSetCoordinator(_))     params.caller == owner;
            case (#handlerGetIndexes(_))        true
        }
    };

    public shared func systemAddCanistersToMap({ canistersPrincipals: [Principal]; canisterKind: CanistersKinds.CanisterKind }) : async () {
        CanistersMap.addCanistersToMap({ map = memoryCanisters; canistersPrincipals = canistersPrincipals; canisterKind = canisterKind });
    };

    public shared func systemSetCoordinator({ coordinatorPrincipalArg: Principal }) : async () {
        coordinatorPrincipal := ?coordinatorPrincipalArg;
    };

    /////////
    // API //
    /////////

    public shared func handlerGetIndexes(kind: CanistersKinds.Indexes) : async [Principal] {
        CanistersMap.getPrincipalsForKind(memoryCanisters, #indexes(kind))
    };
};