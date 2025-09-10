import Principal "mo:core/Principal";
module {
    type canister_settings = {
        controllers : ?[Principal];
        compute_allocation : ?Nat;
        memory_allocation : ?Nat;
        freezing_threshold : ?Nat;
        reserved_cycles_limit : ?Nat;
        log_visibility : ?LogVisibility;
        wasm_memory_limit : ?Nat;
        wasm_memory_threshold : ?Nat;
    };

    type LogVisibility = {
        #controllers; 
        #public_; 
        #allowed_viewers : [Principal] 
    };

    let settings = {
        controllers = [Principal.fromText("your-principal-id")];
        compute_allocation = ?10;
        memory_allocation = ?(1024 * 1024 * 10); // 10 MiB
        freezing_threshold = null;
        reserved_cycles_limit = null;
        log_visibility = null;
        wasm_memory_limit = null;
        wasm_memory_threshold = null;
    };

    public let management = actor ("aaaaa-aa") : actor {
        deposit_cycles : shared {canister_id : Principal} -> async ();
        canister_status : shared { canister_id : Principal } -> async {
                                                                    status : { #stopped; #stopping; #running };
                                                                    memory_size : Nat;
                                                                    cycles : Nat;
                                                                    settings : canister_settings;
                                                                    idle_cycles_burned_per_day : Nat;
                                                                    module_hash : ?[Nat8];
                                                                };
    }
}