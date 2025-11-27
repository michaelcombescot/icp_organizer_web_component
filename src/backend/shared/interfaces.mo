import Principal "mo:core/Principal";

module Interfaces {
    public type Coordinator = actor {
        handlerGetIndexes : shared query () -> async [Principal];
        handlerGetBuckets: shared query({ nature: Nat }) -> async [Principal];
    }
}