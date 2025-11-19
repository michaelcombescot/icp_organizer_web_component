import Principal "mo:core/Principal";
import Result "mo:core/Result";
import CanistersKinds "../ops/canistersKinds";

module Interfaces {
    public type Coordinator = actor {
        handlerGetIndexes : shared query () -> async [Principal];
        handlerGetEmptyBucket: shared query(nature: CanistersKinds.BucketKind) -> async Result.Result<Principal, Text>;
        handlerGetBuckets: shared query(nature: CanistersKinds.BucketKind) -> async [(Principal, CanistersKinds.BucketKind)];
    }
}