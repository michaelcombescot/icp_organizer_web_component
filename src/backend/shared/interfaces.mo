import Principal "mo:core/Principal";
import CanistersKinds "../ops/canistersKinds";

module Interfaces {
    public type Coordinator = actor {
        handlerGetIndexes : shared query () -> async [Principal];
        handlerGetBuckets: shared query({ nature: CanistersKinds.BucketKind }) -> async [Principal];
        handlerGetFreeBucket: shared query({ nature: CanistersKinds.BucketKind }) -> async Principal;
    }
}