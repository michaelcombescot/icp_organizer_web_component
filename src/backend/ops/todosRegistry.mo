import Array "mo:core/Array";
import Principal "mo:core/Principal";
import Map "mo:core/Map";
import CanistersKinds "../shared/canistersKinds";
import CanistersMap "../shared/canistersMap";

// only goal of this canister is too keep track of all the indexes and serve their principal to the frontend.
// not dynamically created, if the need arise another instance will need to be declared in the dfx.json
shared ({ caller = owner }) persistent actor class TodosRegistry() = this {
    
    ////////////
    // MEMORY //
    ////////////

    var memoryCanisters = CanistersMap.arrayToCanistersMap([]);

    var coordinatorPrincipal : ?Principal = null;

    ////////////
    // SYSTEM //
    ////////////

    type InspectParams = {
        arg: Blob;
        caller : Principal;
        msg : {
            #handlerGetIndexes : () -> (kind : CanistersKinds.IndexKind);
            #systemSetCoordinator : () -> {coordinatorPrincipalArg : Principal};
            #systemUpdateCanistersMap : () -> {canisters : [(CanistersKinds.CanisterKind, [Principal])]};
        };
    };

    system func inspect(params: InspectParams) : Bool {
        if ( params.caller == Principal.anonymous() ) { return false; };

        switch ( params.msg ) {
            case (#systemUpdateCanistersMap(_))   ?params.caller == coordinatorPrincipal;
            case (#systemSetCoordinator(_))       params.caller == owner;
            case (#handlerGetIndexes(_))          true
        }
    };

    public shared func systemUpdateCanistersMap({ canisters: [(CanistersKinds.CanisterKind, [Principal])] }) : async () {
        memoryCanisters := CanistersMap.arrayToCanistersMap(canisters);
    };

    public shared func systemSetCoordinator({ coordinatorPrincipalArg: Principal }) : async () {
        coordinatorPrincipal := ?coordinatorPrincipalArg;
    };

    /////////
    // API //
    /////////

    public shared func handlerGetIndexes(kind: CanistersKinds.IndexKind) : async [Principal] {
        let ?indexesPrincipals = Map.get(memoryCanisters, CanistersKinds.compareCanisterKinds, #indexes(kind)) else return [];
        
        Array.fromIter(Map.keys(indexesPrincipals))
    };
};