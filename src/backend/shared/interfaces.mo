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

    public module ManagementCanister {
        public let canister = actor(Configs.CanisterIds.MANAGEMENT_CANISTER) : Self;

        public type canister_settings = {
        freezing_threshold : ?Nat;
        controllers : ?[Principal];
        memory_allocation : ?Nat;
        compute_allocation : ?Nat;
        };

        public type definite_canister_settings = {
        freezing_threshold : Nat;
        controllers : [Principal];
        memory_allocation : Nat;
        compute_allocation : Nat;
        };

        public type wasm_module = [Nat8];

        public type Self = actor {
            canister_status : shared { canister_id : Principal } -> async {
                status : { #stopped; #stopping; #running };
                memory_size : Nat;
                cycles : Nat;
                settings : definite_canister_settings;
                idle_cycles_burned_per_day : Nat;
                module_hash : ?[Nat8];
            };

            create_canister : shared { settings : ?canister_settings } -> async {
                canister_id : Principal;
            };

            delete_canister : shared { canister_id : Principal } -> async ();

            deposit_cycles : shared { canister_id : Principal } -> async ();

            install_code : shared {
                arg : [Nat8];
                wasm_module : wasm_module;
                mode : { #reinstall; #upgrade; #install };
                canister_id : Principal;
            } -> async ();

            start_canister : shared { canister_id : Principal } -> async ();

            stop_canister : shared { canister_id : Principal } -> async ();

            uninstall_code : shared { canister_id : Principal } -> async ();

            update_settings : shared {
                canister_id : Principal;
                settings : canister_settings;
            } -> async ();
        };
    };
}