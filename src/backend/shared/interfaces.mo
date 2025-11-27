import Principal "mo:core/Principal";
import CanistersKinds "../ops/canistersKinds";

module Interfaces {
    public type Coordinator = actor {
        handlerGiveFreeBucket: shared ({ nature: CanistersKinds.BucketKind }) -> async Principal;
    }
}