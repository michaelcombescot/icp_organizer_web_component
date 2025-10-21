import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Configs "./configs";

module {
    public module MaintenanceIndex {
        public let canister = actor(Configs.CanisterIds.INDEX_MAINTENANCE) : Self;

        public type Self = actor {
            addBucket : shared () -> async Result.Result<Principal, Text>;
        };
    };
}