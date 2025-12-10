import Map "mo:core/Map";
import Principal "mo:core/Principal";
import Array "mo:core/Array";
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

    // used to create a new canistersMap from an array, usefull to add several canisters at once in an intercanisters call
    public func arrayToCanistersMap(canisters: [(CanistersKinds.CanisterKind, [Principal])]) : CanistersMap {
        let newMap: CanistersMap = Map.empty<CanistersKinds.CanisterKind, Map.Map<Principal, ()>>();
        for ( (canisterKind, principals) in canisters.values() ) {
            let principalsArrForMap = Array.map(principals, func(principal) = (principal, ()));

            Map.add(newMap, CanistersKinds.compareCanisterKinds, canisterKind, Map.fromIter(principalsArrForMap.values(), Principal.compare));
        };

        newMap
    };

    // used to check if a principal is an index, usefull when checking the caller
    public func isPrincipalInKind(canistersMap: CanistersMap, principal: Principal, kind: CanistersKinds.CanisterKind) : Bool {
        let ?principalsMap = Map.get(canistersMap, CanistersKinds.compareCanisterKinds, kind) else return false;
        let ?_ = Map.get(principalsMap, Principal.compare, principal) else return false;
        
        true
    };

    public func getPrincipalsForKind(canistersMap: CanistersMap, kind: CanistersKinds.CanisterKind) : [Principal] {
        switch ( Map.get(canistersMap, CanistersKinds.compareCanisterKinds, kind) ) {
            case null [];
            case (?mapPrincipals) Array.fromIter( Map.keys(mapPrincipals));
        }   
    };
};