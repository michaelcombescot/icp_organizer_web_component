import IC "mo:ic";
import Interfaces "../../shared/interfaces";
import Principal "mo:core/Principal";
import Debug "mo:core/Debug";
import Result "mo:base/Result";

// used to handle authorization of canisters
mixin({ coordinatorPrincipal: Principal; canisterPrincipal: Principal; toppingThreshold: Nat; toppingAmount: Nat; toppingIntervalNs: Nat }) {
    let coordinatorActor = actor(Principal.toText(coordinatorPrincipal)) : Interfaces.Coordinator;

    func topCanisterRequest() : async () {
        let status = await IC.ic.canister_status({ canister_id = canisterPrincipal });
        if (status.cycles <= toppingThreshold) {

            switch (await coordinatorActor.topCanister(canisterPrincipal, toppingAmount)) {
                case (#ok) ();
                case (#err(err)) Debug.print("cannot top canister" # canisterPrincipal.toText() # ", error: " # err)
            }
        };
    };

    // func createNewBucket() : async Result.Result<(), Text> {
    //     try {

    //     }
    // };
};