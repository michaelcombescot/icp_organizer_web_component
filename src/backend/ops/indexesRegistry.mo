import Principal "mo:core/Principal";
import Blob "mo:core/Blob";
import Map "mo:core/Map";
import Iter "mo:core/Iter";
import List "mo:core/List";
import CanistersKinds "../shared/canistersKinds";

// only goal of this canister is too keep track of all the indexes and serve their principal to the frontend.
// not dynamically created, if the need arise another instance will need to be declared in the dfx.json
shared ({ caller = owner }) persistent actor class IndexesRegistry() = this {
    
    ////////////
    // MEMORY //
    ////////////

    var coordinatorPrincipal : ?Principal = null;

    let memoryIndexes = Map.empty<CanistersKinds.IndexesKind, List.List<Principal>>();

    ////////////
    // SYSTEM //
    ////////////

    type InspectParams = {
        arg: Blob;
        caller : Principal;
        msg : {
            #systemSetCoordinator : () -> (coordinatorPrincipalArg : Principal);
            #systemAddIndex : () -> (indexPrincipal : Principal, indexKind : CanistersKinds.IndexesKind);

            #handlerGetIndexes : () -> ();
        };
    };

    system func inspect(params: InspectParams) : Bool {
        if ( params.caller == Principal.anonymous() ) { return false; };

        if ( Blob.size(params.arg) > 0 ) { return false; };

        switch ( params.msg ) {
            case (#systemSetCoordinator(_))     params.caller == owner;
            case (#systemAddIndex(_))           ?params.caller == coordinatorPrincipal or params.caller == owner;
            case (#handlerGetIndexes(_))        true
        }
    };

    public shared func systemSetCoordinator(coordinatorPrincipalArg: Principal) : async () {
        coordinatorPrincipal := ?coordinatorPrincipalArg;
    };

    public shared func systemAddIndex(indexPrincipal: Principal, indexKind: CanistersKinds.IndexesKind) : async () {
        switch ( memoryIndexes.get(CanistersKinds.compareIndexesKind, indexKind) ) {
            case (null) memoryIndexes.add(CanistersKinds.compareIndexesKind, indexKind, List.singleton(indexPrincipal));
            case (?list) list.add(indexPrincipal);    
        };
    };

    /////////
    // API //
    /////////

    public shared func handlerGetIndexes() : async [(CanistersKinds.IndexesKind, [Principal])] {
        let newMap = memoryIndexes.map(func(k,v) = v.toArray());
        Iter.toArray(newMap.entries())
    };
};