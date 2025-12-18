import Principal "mo:core/Principal";
import CanistersKinds "canistersKinds";

module Interfaces {
    public type Coordinator = actor {
        handlerGiveNewBucket: shared ({ bucketKind: CanistersKinds.BucketsKind }) -> async Principal;
        handlerIsLegitCanister: shared ({ canisterPrincipal: Principal }) -> async Bool;
    };
}