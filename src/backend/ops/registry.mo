import Array "mo:core/Array";
import Principal "mo:core/Principal";
import Map "mo:core/Map";
import Iter "mo:core/Iter";
import CanistersKinds "canistersKinds";

shared ({ caller = owner }) persistent actor class Registry() = this {
    
    ////////////
    // MEMORY //
    ////////////

    var coordinatorPrincipal: ?Principal = null;

    var memoryIndexes = Map.empty<CanistersKinds.IndexKind, [Principal]>();

    ////////////
    // SYSTEM //
    ////////////

    type Msg = {
        #getIndexes : () -> ();
        #setCoordinator : () -> {coordinatorPrincipalArg : Principal};
        #updateIndexes : () -> {indexes : [(CanistersKinds.IndexKind, [Principal])]}
    };

    system func inspect({ caller : Principal; msg : Msg }) : Bool {
        switch msg {
            case (#setCoordinator(_)) {
                if ( caller != owner ) { return false; };
            };
            case (#updateIndexes(_)) {
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

    public shared func updateIndexes({ indexes: [(CanistersKinds.IndexKind, [Principal])] }) : async () {
        memoryIndexes := Map.fromIter(indexes.values(), CanistersKinds.compareIndexesKinds);
    };

    public shared func getIndexes() : async [{ indexKind: CanistersKinds.IndexKind; principals: [Principal] }] {
        Array.fromIter(
            Iter.map(
                Map.entries(memoryIndexes),
                func(indexKind, principals) = { indexKind = indexKind; principals = principals }
            )
        )
    };
};