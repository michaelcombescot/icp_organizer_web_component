module {
    public module Consts {
        public let TOPPING_TIMER_INTERVAL_NS    = 20_000_000_000;
        public let TOPPING_THRESHOLD            = 1_000_000_000_000;
        public let TOPPING_AMOUNT               = 1_000_000_000_000;

        public let NEW_BUCKET_NB_CYCLES = 2_000_000_000_000;


        public let BUCKET_USERS_DATA_MAX_ENTRIES = 1000;
        public let BUCKET_TODOS_MAX_ENTRIES = 10000;
    };

    public module CanisterIds {
        // canisters owned
        public let INDEX_MAINTENANCE = "aaaaa-aa";
        public let INDEX_USERS_DATA = "aaaaa-aa";
        public let INDEX_TODOS = "aaaaa-aa";

        // canisters not owned
        public let MANAGEMENT_CANISTER = "aaaaa-aa";
    }
}