import Principal "mo:core/Principal";
import Result "mo:core/Result";
import CanistersKinds "canistersKinds";

module Interfaces {
    public type Coordinator = actor {
        topCanister: shared (canisterPrincipal: Principal, nbCycles: Nat) -> async Result.Result<(), Text>;

        handlerCreateBucket: shared (bucketKind: CanistersKinds.BucketsKind) -> async Result.Result<Principal, Text>;
        handlerIsLegitCanister: shared (canisterPrincipal: Principal) -> async Bool;
    };
}