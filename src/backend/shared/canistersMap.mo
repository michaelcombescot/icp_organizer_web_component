import Map "mo:core/Map";
import Principal "mo:core/Principal";
import Array "mo:core/Array";
import Option "mo:core/Option";
import CanistersKinds "canistersKinds";

module {
    public type CanistersMap = Map.Map<CanistersKinds.CanisterKind, Map.Map<Principal, ()>>;

    public func arrayToCanistersMap(canisters: [(CanistersKinds.CanisterKind, [Principal])]) : CanistersMap {
        let newMap: CanistersMap = Map.empty<CanistersKinds.CanisterKind, Map.Map<Principal, ()>>();
        for ( (canisterKind, principals) in canisters.values() ) {
            let principalsArrForMap = Array.map(principals, func(principal) = (principal, ()));

            Map.add(newMap, CanistersKinds.compareCanisterKinds, canisterKind, Map.fromIter(principalsArrForMap.values(), Principal.compare));
        };

        newMap
    };

    public func isPrincipalInCanistersMap({ canistersMap: CanistersMap; principal: Principal; canisterKind: CanistersKinds.CanisterKind }) : Bool {
        let ?mapPrincipals = Map.get(canistersMap, CanistersKinds.compareCanisterKinds, canisterKind) else return false;

        Option.isSome(Map.get(mapPrincipals, Principal.compare, principal))
    };

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