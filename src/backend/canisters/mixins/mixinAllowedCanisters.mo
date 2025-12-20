import Interfaces "../../shared/interfaces";
import Map "mo:core/Map";
import Principal "mo:core/Principal";

// used to handle authorization of canisters
mixin(coordinatorPrincipal: Principal) {
    let coordinatorActor = actor(Principal.toText(coordinatorPrincipal)) : Interfaces.Coordinator;

    let allowedCanisters = Map.empty<Principal, Bool>();

    func systemHelperIsCanisterAllowed(canisterPrincipal: Principal) : async Bool {
        switch ( allowedCanisters.get(canisterPrincipal) ) {
            case (?allowed) return allowed;
            case null {
                let allowed = await coordinatorActor.handlerIsLegitCanister(canisterPrincipal);
                allowedCanisters.add(canisterPrincipal, allowed);
                allowed
            };
        }
    };
};