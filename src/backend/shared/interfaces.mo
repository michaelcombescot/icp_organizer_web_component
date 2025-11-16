import Principal "mo:core/Principal";

module Interfaces {
    public type Coordinator = actor {
        getIndexes : shared query () -> async [Principal];
    }
}