import Map "mo:core/Map";
import Principal "mo:core/Principal";
import Array "mo:core/Array";
import Option "mo:core/Option";
import CanistersKinds "canistersKinds";

module {
    public type CanistersMap = Map.Map<CanistersKinds.CanisterKind, Map.Map<Principal, ()>>;

    // used to create a new empty canistersMap
    public func newCanisterMap() : CanistersMap {
        Map.empty<CanistersKinds.CanisterKind, Map.Map<Principal, ()>>()
    };

    // add a canister to a canistersMap
    public func addCanisterToMap({ map: CanistersMap; canisterPrincipal: Principal; canisterKind: CanistersKinds.CanisterKind }) {
        switch ( Map.get(map , CanistersKinds.compareCanisterKinds, canisterKind) ) {
            case null Map.add(map, CanistersKinds.compareCanisterKinds, canisterKind, Map.singleton<Principal, ()>(canisterPrincipal, ()));
            case (?canistersMap) Map.add(canistersMap, Principal.compare, canisterPrincipal, ());
        };
    };

    // used to create a new canistersMap from an array, usefull to sens several canisters at once in an intercanisters call
    public func arrayToCanistersMap(canisters: [(CanistersKinds.CanisterKind, [Principal])]) : CanistersMap {
        let newMap: CanistersMap = Map.empty<CanistersKinds.CanisterKind, Map.Map<Principal, ()>>();
        for ( (canisterKind, principals) in canisters.values() ) {
            let principalsArrForMap = Array.map(principals, func(principal) = (principal, ()));

            Map.add(newMap, CanistersKinds.compareCanisterKinds, canisterKind, Map.fromIter(principalsArrForMap.values(), Principal.compare));
        };

        newMap
    };

    // used to check if a principal is in a canistersMap, usefull when checking the caller
    public func isPrincipalInCanistersMap({ canistersMap: CanistersMap; principal: Principal; canisterKind: CanistersKinds.CanisterKind }) : Bool {
        let ?mapPrincipals = Map.get(canistersMap, CanistersKinds.compareCanisterKinds, canisterKind) else return false;

        Option.isSome(Map.get(mapPrincipals, Principal.compare, principal))
    };

    // used to check if a principal is an index, usefull when checking the caller
    public func isPrincipalAnIndex(canistersMap: CanistersMap, principal: Principal) : Bool {
        for (kind in CanistersKinds.indexKindArray.values()) {
            let wrappedKind: CanistersKinds.CanisterKind = switch (kind) {
                                                            case (#todosGroupsIndex) #indexes(#todosGroupsIndex);
                                                            case (#todosUsersIndex) #indexes(#todosUsersIndex);
                                                        };

            let ?principalMap = Map.get(canistersMap, CanistersKinds.compareCanisterKinds, wrappedKind) else return false;

            if ( Option.isSome(Map.get(principalMap, Principal.compare, principal)) ) { return true };
        };

        return false
    };
};