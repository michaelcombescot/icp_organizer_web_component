import Principal "mo:core/Principal";
import Result "mo:core/Result";
import CanistersKinds "canistersKinds";

module Interfaces {
    public type Coordinator = actor {
        topCanister: shared (canisterPrincipal: Principal, nbCycles: Nat) -> async Result.Result<(), Text>;

        handlerGiveNewBucket: shared ({ bucketKind: CanistersKinds.BucketsKind }) -> async Principal;
        handlerIsLegitCanister: shared (canisterPrincipal: Principal) -> async Bool;
    };
}