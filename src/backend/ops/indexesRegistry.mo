import Principal "mo:core/Principal";
import Blob "mo:core/Blob";
import Map "mo:core/Map";
import Iter "mo:core/Iter";
import CanistersKinds "../shared/canistersKinds";

// only goal of this canister is too keep track of all the indexes and serve their principal to the frontend.
// not dynamically created, if the need arise another instance will need to be declared in the dfx.json
shared ({ caller = owner }) persistent actor class IndexesRegistry() = this {
    
    ////////////
    // MEMORY //
    ////////////

    var coordinatorPrincipal : ?Principal = null;

    let memoryIndexes = Map.empty<Principal, CanistersKinds.IndexesKind>();

    ////////////
    // SYSTEM //
    ////////////

    type InspectParams = {
        arg: Blob;
        caller : Principal;
        msg : {
            #systemSetCoordinator : () -> (coordinatorPrincipalArg : Principal);
            #systemSetIndex : () -> (indexPrincipal : Principal, indexKind : CanistersKinds.IndexesKind);

            #handlerGetIndexes : () -> ();
        };
    };

    system func inspect(params: InspectParams) : Bool {
        if ( params.caller == Principal.anonymous() ) { return false; };

        if ( Blob.size(params.arg) > 0 ) { return false; };

        switch ( params.msg ) {
            case (#systemSetCoordinator(_))     params.caller == owner;
            case (#systemSetIndex(_))           ?params.caller == coordinatorPrincipal;
            case (#handlerGetIndexes(_))        true
        }
    };

    public shared func systemSetCoordinator(coordinatorPrincipalArg: Principal) : async () {
        coordinatorPrincipal := ?coordinatorPrincipalArg;
    };

    public shared func systemSetIndex(indexPrincipal: Principal, indexKind: CanistersKinds.IndexesKind) : async () {
        memoryIndexes.add(indexPrincipal, indexKind);
    };

    /////////
    // API //
    /////////

    public shared func handlerGetIndexes() : async [(Principal, CanistersKinds.IndexesKind)] {
        Iter.toArray(Map.entries(memoryIndexes))
    };
};