import Principal "mo:core/Principal";
import CanistersKinds "canistersKinds";

module Interfaces {
    public type Coordinator = actor {
        handlerGiveFreeBucket: shared ({ bucketKind: CanistersKinds.Buckets }) -> async Principal;
    };
}