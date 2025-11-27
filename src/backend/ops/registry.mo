import Array "mo:core/Array";
import Principal "mo:core/Principal";
import Map "mo:core/Map";
import Iter "mo:core/Iter";
import List "mo:core/List";
import CanistersKinds "canistersKinds";

shared ({ caller = owner }) persistent actor class Registry() = this {
    
    ////////////
    // MEMORY //
    ////////////

    var coordinatorPrincipal: ?Principal = null;

    var memoryIndexes = Map.empty<CanistersKinds.IndexKind, List.List<Principal>>();

    ////////////
    // SYSTEM //
    ////////////

    type Msg = {
        #getIndexes : () -> ();
        #setCoordinator : () -> {coordinatorPrincipalArg : Principal};
        #addIndex : () -> { kind: CanistersKinds.IndexKind; principal: Principal }
    };

    system func inspect({ caller : Principal; msg : Msg }) : Bool {
        switch msg {
            case (#setCoordinator(_)) {
                if ( caller != owner ) { return false; };
            };
            case (#addIndex (_)) {
                if ( ?caller != coordinatorPrincipal ) { return false; };
            };
            case (#getIndexes(_)) ();
        };

        return true
    };

    /////////
    // API //
    /////////

    public shared func setCoordinator({ coordinatorPrincipalArg: Principal }) : async () {
        coordinatorPrincipal := ?coordinatorPrincipalArg;
    };

    public shared func addIndex({ kind: CanistersKinds.IndexKind; principal: Principal }) : async () {
        switch ( Map.get(memoryIndexes, CanistersKinds.compareIndexesKinds, kind) ) {
            case null Map.add(memoryIndexes, CanistersKinds.compareIndexesKinds, kind, List.singleton<Principal>(principal));
            case (?list) List.add(list, principal);  
        };
    };

    public shared func getIndexes() : async [{ indexKind: CanistersKinds.IndexKind; principals: [Principal] }] {
        Array.fromIter(
            Iter.map(
                Map.entries(memoryIndexes),
                func(indexKind, principals) = { indexKind = indexKind; principals = List.toArray(principals) }
            )
        )
    };
};