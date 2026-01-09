import IC "mo:ic";
import Interfaces "../../shared/interfaces";
import Principal "mo:core/Principal";
import Debug "mo:core/Debug";

// used to handle authorization of canisters
mixin(coordinatorActor: Interfaces.Coordinator, canisterPrincipal: Principal, toppingThreshold: Nat, toppingAmount: Nat) {
    func topCanisterRequest() : async () {
        let status = await IC.ic.canister_status({ canister_id = canisterPrincipal });
        if (status.cycles <= toppingThreshold) {

            switch (await coordinatorActor.topCanister(canisterPrincipal, toppingAmount)) {
                case (#ok) ();
                case (#err(err)) Debug.print("cannot top canister" # canisterPrincipal.toText() # ", error: " # err)
            }
        };
    };
};