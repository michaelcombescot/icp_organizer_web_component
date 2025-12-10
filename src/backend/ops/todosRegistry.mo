import Principal "mo:core/Principal";
import CanistersKinds "../shared/canistersKinds";
import CanistersMap "../shared/canistersMap";

// only goal of this canister is too keep track of all the indexes and serve their principal to the frontend.
// not dynamically created, if the need arise another instance will need to be declared in the dfx.json
shared ({ caller = owner }) persistent actor class TodosRegistry() = this {
    
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
            #systemAddCanisterToMap : () -> { canisterPrincipal: Principal; canisterKind: CanistersKinds.CanisterKind };
            #systemSetCoordinator : () -> {coordinatorPrincipalArg : Principal};

            #handlerGetIndexes : () -> ();
        };
    };

    system func inspect(params: InspectParams) : Bool {
        if ( params.caller == Principal.anonymous() ) { return false; };

        switch ( params.msg ) {
            case (#systemAddCanisterToMap(_))   ?params.caller == coordinatorPrincipal;
            case (#systemSetCoordinator(_))       params.caller == owner;
            case (#handlerGetIndexes(_))          true
        }
    };

    public shared func systemAddCanisterToMap({ canisterPrincipal: Principal; canisterKind: CanistersKinds.CanisterKind }) : async () {
        CanistersMap.addCanisterToMap({ map = memoryCanisters; canisterPrincipal = canisterPrincipal; canisterKind = canisterKind });
    };

    public shared func systemSetCoordinator({ coordinatorPrincipalArg: Principal }) : async () {
        coordinatorPrincipal := ?coordinatorPrincipalArg;
    };

    /////////
    // API //
    /////////

    public shared func handlerGetIndexes() : async [Principal] {
        CanistersMap.getPrincipalsForKind(memoryCanisters, #todosIndex)
    };
};