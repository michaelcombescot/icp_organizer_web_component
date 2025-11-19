import Debug "mo:core/Debug";
import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Map "mo:core/Map";
import Nat64 "mo:core/Nat64";
import Time "mo:core/Time";
import Nat "mo:core/Nat";
import Error "mo:core/Error";
import Blob "mo:core/Blob";
import IC "mo:ic";
import TodosIndex "../todos/todosIndex";
import List "mo:core/List";
import Array "mo:core/Array";
import CanistersKinds "canistersKinds";
import TodosTodosBucket "../todos/buckets/todosTodosBucket";
import TodosUsersDataBucket "../todos/buckets/todosUsersDataBucket";
import TodosListsBucket "../todos/buckets/todosListsBucket";
import TodosGroupsBucket "../todos/buckets/todosGroupsBucket";

// The coordinator is the main entry point to launch the application.
// Launching the coordinator will create all necessary buckets and indexes, it's the ONLY entry point, everything else is dynamically created.
// It will have several missions:
// - create buckets and indexes
// - top indexes and canisters with cycles
// - check if there are free buckets in the bucket pool.The bucket pool is here for the different indexes to pick new active buckets when a buckets return a signal it's full.
shared ({ caller = owner }) persistent actor class Coordinator() = this {
    let ERR_CAN_ONLY_BE_CALLED_BY_OWNER     = "ERR_CAN_ONLY_BE_CALLED_BY_OWNER";
    let ERR_CAN_ONLY_BE_CALLED_BY_BUCKETS   = "ERR_CAN_ONLY_BE_CALLED_BY_BUCKETS";
    let ERR_CAN_ONLY_BE_CALLED_BY_INDEX     = "ERR_CAN_ONLY_BE_CALLED_BY_INDEX";

    //
    // CONFIGS
    //

    let TOPPING_TIMER_INTERVAL_NS   = 20_000_000_000;
    let TOPPING_THRESHOLD           = 1_000_000_000_000;
    let TOPPING_AMOUNT_BUCKETS      = 1_000_000_000_000;
    let TOPPING_AMOUNT_INDEXES      = 1_000_000_000_000;

    let NEW_BUCKET_NB_CYCLES        = 2_000_000_000_000;

    let NB_EMPTY_BUCKETS_PER_TYPE   = 1;

    //
    // STATES
    //

    var storeCanisters          = Map.empty<CanistersKinds.CanisterKind , Map.Map<Principal, ()>>();
    var storeEmptyBuckets       = Map.empty<CanistersKinds.BucketKind, List.List<Principal>>();

    //
    // SYSTEM
    //

    // the timer has 2 functions:
    // - topping buckets/indexes with cycles
    // - check if there are free buckets in the bucket pool
    system func timer(setGlobalTimer : (Nat64) -> ()) : async () {
        // topping cycles
        // TODO performances: parrallelize the calls
        for ( (nature, typeMap) in Map.entries(storeCanisters) ) {
            let toppingAmount = switch (nature) {
                                    case (#indexes(indexesKind)) {
                                        switch indexesKind {
                                            case (#todosIndex) TOPPING_AMOUNT_INDEXES;
                                        }
                                    };
                                    case (#buckets(bucketsKind)) {
                                        switch bucketsKind {
                                            case(#todos(todoBuckets)) {
                                                switch (todoBuckets) {
                                                    case (#todosTodosBucket) TOPPING_AMOUNT_BUCKETS;
                                                    case (#todosUsersDataBucket) TOPPING_AMOUNT_BUCKETS;
                                                    case (#todosListsBucket) TOPPING_AMOUNT_BUCKETS;
                                                    case (#todosGroupsBucket) TOPPING_AMOUNT_BUCKETS;
                                                }
                                            }
                                        };
                                    };                                   
                                };


            for ( canisterPrincipal in Map.keys(typeMap) ) { 
                ignore helperTopCanisterCycles(canisterPrincipal, toppingAmount);
            };
        };

        // create new bucket if necessary in the buckets pool
        // TODO performances: parrallelize the calls
        for ( nature in CanistersKinds.bucketKindArray.values() ) {
            switch ( Map.get(storeEmptyBuckets, CanistersKinds.compareBucketsKinds, nature) ) {
                case null ignore helperCreateBucket(nature);
                case (?typeMap) {
                    if (List.size(typeMap) < NB_EMPTY_BUCKETS_PER_TYPE) {
                        ignore helperCreateBucket(nature);
                    };
                };
            };
        };

        // set timer
        setGlobalTimer(Nat64.fromIntWrap(Time.now()) + Nat64.fromNat(TOPPING_TIMER_INTERVAL_NS));
    };
    
    func helperTopCanisterCycles(canisterPrincipal : Principal, amount: Nat) : async () {
        let status = await IC.ic.canister_status({ canister_id = canisterPrincipal });
        if (status.cycles > TOPPING_THRESHOLD) {
            Debug.print("Bucket low on cycles, requesting top-up for " # Principal.toText(canisterPrincipal) # "with " # Nat.toText(amount) # " cycles");

            try {
                ignore (with cycles = amount) IC.ic.deposit_cycles({ canister_id = canisterPrincipal });
            } catch (e) {
                Debug.print("Error while topping up bucket " # Principal.toText(canisterPrincipal) # ": " # Error.message(e));
            };
        };
    };

    func helperCreateBucket(bucketType : CanistersKinds.BucketKind) : async () {
        try {
            let aktor = await switch (bucketType) {
                                case (#todos(todoType)) {
                                    switch (todoType) {
                                        case (#todosTodosBucket)        (with cycles = NEW_BUCKET_NB_CYCLES) TodosTodosBucket.TodosTodosBucket();
                                        case (#todosUsersDataBucket)    (with cycles = NEW_BUCKET_NB_CYCLES) TodosUsersDataBucket.TodosUsersDataBucket();
                                        case (#todosListsBucket )       (with cycles = NEW_BUCKET_NB_CYCLES) TodosListsBucket.TodosListsBucket();
                                        case (#todosGroupsBucket)       (with cycles = NEW_BUCKET_NB_CYCLES) TodosGroupsBucket.TodosGroupsBucket();
                                    };
                                };
                        };

            let newPrincipal = Principal.fromActor(aktor);

            switch ( Map.get(storeEmptyBuckets, CanistersKinds.compareBucketsKinds, bucketType) ) {
                case null Map.add(storeEmptyBuckets, CanistersKinds.compareBucketsKinds, bucketType, List.singleton<Principal>(newPrincipal));
                case (?list) List.add(list, newPrincipal);
            };
        } catch (e) {
            Debug.print("Cannot create new bucket of type: " # debug_show(bucketType) # ", error: " # Error.message(e));
        };     
    };

    func helperCreateIndex(indexType : CanistersKinds.IndexKind) : async Principal {
        try {
            let aktor = await switch (indexType) {
                            case (#todosIndex) (with cycles = NEW_BUCKET_NB_CYCLES) TodosIndex.TodosIndex();
                        };

            let newPrincipal = Principal.fromActor(aktor);

            switch ( Map.get(storeCanisters, CanistersKinds.compareCanisterKinds, #indexes(indexType)) ) {
                case null Map.add(storeCanisters, CanistersKinds.compareCanisterKinds, #indexes(indexType), Map.singleton<Principal, ()>(newPrincipal, ()));
                case (?map) Map.add(map, Principal.compare, newPrincipal, ());
            };
        } catch (e) {
            Debug.print("Cannot create new index of type: " # debug_show(indexType) # ", error: " # Error.message(e));
        }
    };

    func helperGetBucketsPrincipals() : List.List<Principal> {
        let buckets = List.empty<Principal>();

        for ( nature in CanistersKinds.bucketKindArray.values() ) {
            switch (nature) {
                case (#todos(todoType)) {
                    switch (todoType) {
                        case (#todosTodosBucket or #todosUsersDataBucket or #todosListsBucket or #todosGroupsBucket) {
                            switch ( Map.get(storeCanisters, CanistersKinds.compareCanisterKinds, #buckets(nature)) ) {
                                case (?typeMap) {
                                    for ( canisterPrincipal in Map.keys(typeMap) ) {
                                        List.add(buckets, canisterPrincipal);
                                    };
                                };
                                case null ();
                            };
                        };
                    }
                }
            }    
        };

        return buckets;
    };

    func helperGetIndexesPrincipals() : List.List<Principal> {
        let indexes = List.empty<Principal>();

        for ( nature in CanistersKinds.indexKindArray.values() ) {
            switch (nature) {
                case (#todosIndex) {
                    switch ( Map.get(storeCanisters, CanistersKinds.compareCanisterKinds, #indexes(nature)) ) {
                        case (?typeMap) {
                            for ( canisterPrincipal in Map.keys(typeMap) ) {
                                List.add(indexes, canisterPrincipal);
                            };
                        };
                        case null ();
                    };
                };
            }    
        };

        return indexes;
    };

    //
    // API
    //

    // create a new index, the main function to scale, must be called by hand
    public shared ({ caller }) func handlerCreateIndex({nature: CanistersKinds.IndexKind}) : async Result.Result<(), Text> {
        if (caller != owner) { return #err(ERR_CAN_ONLY_BE_CALLED_BY_OWNER); };

        #ok( await helperCreateIndex(nature) )
    };

    // retrieve Principal of all indexes of a specific type
    public shared ({ caller }) func handlerGetIndexes({nature: CanistersKinds.IndexKind}) : async Result.Result<[Principal], Text> {
        if ( List.contains(helperGetBucketsPrincipals(), Principal.equal, caller) ) { return #err(ERR_CAN_ONLY_BE_CALLED_BY_BUCKETS); };

        let ?indexes = Map.get(storeCanisters, CanistersKinds.compareCanisterKinds, #indexes(nature)) else return #err("No indexes of type " # debug_show(nature) # " found");
        #ok( Array.fromIter( Map.keys(indexes) ) );
    };

    // retrieve Principal of all buckets of a specific type
    public shared ({ caller }) func handlerGetBuckets({nature: CanistersKinds.BucketKind}) : async Result.Result<[(Principal, CanistersKinds.BucketKind)], Text> {
        if ( List.contains(helperGetIndexesPrincipals(), Principal.equal, caller) ) { return #err(ERR_CAN_ONLY_BE_CALLED_BY_INDEX); };

        let ?buckets = Map.get(storeCanisters, CanistersKinds.compareCanisterKinds, #buckets(nature)) else return #err("No buckets of type " # debug_show(nature) # " found");
        #ok( Array.fromIter( Map.keys(buckets) ) );
    };

    // retrieve Principal of an empty bucket of a specific type. Must be queried by an index when needed
    public shared ({ caller }) func handlerGetEmptyBucket({ nature : CanistersKinds.BucketKind }) : async Result.Result<Principal, Text> {
        if ( List.contains(helperGetIndexesPrincipals(), Principal.equal, caller) ) { return #err(ERR_CAN_ONLY_BE_CALLED_BY_BUCKETS); };

        let ?buckets = Map.get(storeEmptyBuckets, CanistersKinds.compareBucketsKinds, nature) else return #err("No empty buckets of type " # debug_show(nature) # " found");
        let ?bucket = List.get(buckets, 0) else return #err("No empty buckets of type " # debug_show(nature) # " found");

        #ok( bucket );
    };

    // upgrade a canister of a specific type, is to be used in cli with the command (replace for the right canister path):
    // - dfx canister call organizerMaintenance upgradeAllBuckets '(#buckettype, blob "'$(hexdump -ve '1/1 "\\\\%02x"' .dfx/local/canisters/organizerUsersDataBucket/organizerUsersDataBucket.wasm)'")'
    public shared ({ caller }) func handlerUpgradeCanister({ nature : CanistersKinds.CanisterKind; code: Blob.Blob }) : async Result.Result<(), Text> {
        if (caller != owner) { return #err(ERR_CAN_ONLY_BE_CALLED_BY_OWNER); };

        let ?canistersMap = Map.get(storeCanisters, CanistersKinds.compareCanisterKinds, nature) else return #err("No canisters of type " # debug_show(nature) # " found");

        for ( canisterPrincipal in Map.keys(canistersMap) ) {
            try {
                ignore IC.ic.install_code({ mode = #upgrade(null); canister_id = canisterPrincipal; wasm_module = code; arg = to_candid((Principal.anonymous())); sender_canister_version = null; });                   
            } catch (e) {
                Debug.print("Cannot upgrade bucket, error: " # Error.message(e));
            };
        };

        #ok()
    };
};