import Debug "mo:core/Debug";
import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Map "mo:core/Map";
import Nat64 "mo:core/Nat64";
import Time "mo:core/Time";
import Nat "mo:core/Nat";
import Error "mo:core/Error";
import Runtime "mo:core/Runtime";
import Array "mo:core/Array";
import Blob "mo:core/Blob";
import IC "mo:ic";
import TodosIndex "../todos/todosIndex";
import List "mo:core/List";
import Iter "mo:core/Iter";
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
    let ERR_CAN_ONLY_BE_CALLED_BY_OWNER = "ERR_CAN_ONLY_BE_CALLED_BY_OWNER";

    //
    // CONFIGS
    //

    let TOPPING_TIMER_INTERVAL_NS   = 20_000_000_000;
    let TOPPING_THRESHOLD           = 1_000_000_000_000;
    let TOPPING_AMOUNT_BUCKETS      = 1_000_000_000_000;
    let TOPPING_AMOUNT_INDEXES      = 1_000_000_000_000;

    let NEW_BUCKET_NB_CYCLES        = 2_000_000_000_000;

    //
    // STATES
    //

    var storeCanisters          = Map.empty<CanistersKinds.CanisterKind , Map.Map<Principal, ()>>();
    var storeEmptyBuckets       = Map.empty<CanistersKinds.BucketKind   , Map.Map<Principal, ()>>();

    //
    // SYSTEM
    //

    // the timer has 2 functions:
    // - topping buckets/indexes with cycles
    // - check if there are free buckets in the bucket pool
    system func timer(setGlobalTimer : (Nat64) -> ()) : async () {
        // topping cycles
        // TODO performances: parrallelize the calls
        for ( typeMap in Map.values(storeCanisters) ) {
            for ( canisterPrincipal in Map.keys(typeMap) ) { 
                ignore topCanisterCycles(canisterPrincipal, TOPPING_AMOUNT_BUCKETS);
            };
        };

        // create new bucket if necessary in the buckets pool
        // TODO performances: parrallelize the calls
        for ( (nature, typeMap) in Map.entries(storeEmptyBuckets) ) {
            if ( typeMap.size < 2 ) {
                ignore createCanister(nature);
            }
        };

        // set timer
        setGlobalTimer(Nat64.fromIntWrap(Time.now()) + Nat64.fromNat(TOPPING_TIMER_INTERVAL_NS));
    };

    
    func topCanisterCycles(canisterPrincipal : Principal, amount: Nat) : async () {
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

    func createCanister(bucketType : CanistersKinds.BucketKind) : async () {
        try {
            let aktor = await switch (bucketType) {
                            case (#todosTodosBucket)        (with cycles = NEW_BUCKET_NB_CYCLES) TodosTodosBucket.TodosTodosBucket();
                            case (#todosUsersDataBucket)    (with cycles = NEW_BUCKET_NB_CYCLES) TodosUsersDataBucket.TodosUsersDataBucket();
                            case (#todosListsBucket )       (with cycles = NEW_BUCKET_NB_CYCLES) TodosListsBucket.TodosListsBucket();
                            case (#todosGroupsBucket)       (with cycles = NEW_BUCKET_NB_CYCLES) TodosGroupsBucket.TodosGroupsBucket();
                        };

            switch ( Map.get(storeEmptyBuckets, CanistersKinds.compareCanisterKinds, bucketType) ) {
                case null ();
                case (?typeMap) Map.add(typeMap, Principal.compare, Principal.fromActor(aktor), ());
            };
        } catch (e) {
            Debug.print("Cannot create new bucket of type: " # debug_show(bucketType) # ", error: " # Error.message(e));
        };         
    };

    //
    // API
    //

    // public shared ({ caller }) func createIndex({nature: Indexes.IndexeType}) : async Result.Result<Principal, Text> {
    //     if (caller != owner) { return #err(ERR_CAN_ONLY_BE_CALLED_BY_OWNER); };

                
    // };

    // public shared ({ caller }) func upgradeAllBuckets(nature : Bucket, code: Blob.Blob) : async Result.Result<(), Text> {
    //     if (caller != owner) { return #err(Errors.ERR_CAN_ONLY_BE_CALLED_BY_OWNER); };

    //     switch (nature) {
    //         case (#usersDataBucket) {
    //             for (principal in Map.keys(bucketsUserDataPrincipals)) {
    //                 try {
    //                     await IC.ic.install_code({ mode = #upgrade(null); canister_id = principal; wasm_module = code; arg = to_candid((Principal.anonymous())); sender_canister_version = null; });
    //                 } catch (e) {
    //                     Debug.print("Cannot upgrade UserData bucket " # Principal.toText(principal) # ": " # Error.message(e));
    //                 };
    //             }
    //         };
    //         case (#todosBucket) {
    //             for (principal in Map.keys(bucketsTodosPrincipals)) {
    //                 try {
    //                     await IC.ic.install_code({ mode = #upgrade(null); canister_id = principal; wasm_module = code; arg = to_candid((Principal.anonymous())); sender_canister_version = null; });
    //                 } catch (e) {
    //                     Debug.print("Cannot upgrade UserData bucket " # Principal.toText(principal) # ": " # Error.message(e));
    //                 };
    //             }
    //         };
    //         case (#groupsBucket) {
    //             for (principal in Map.keys(bucketsGroupsPrincipals)) {
    //                 try {
    //                     await IC.ic.install_code({ mode = #upgrade(null); canister_id = principal; wasm_module = code; arg = to_candid((Principal.anonymous())); sender_canister_version = null; });
    //                 } catch (e) {
    //                     Debug.print("Cannot upgrade UserData bucket " # Principal.toText(principal) # ": " # Error.message(e));
    //                 };
    //             }
    //         };
    //     };

    //     #ok()
    // };

    // public shared ({ caller }) func createBucket(typ: Types.TodoBucketType) : async Result.Result<Principal, Text> {
    //     let bucketprincipal =   if ( caller == indexUserDataPrincipal ) {
    //                                 try {
    //                                     let aktor = await (with cycles = Configs.Consts.NEW_BUCKET_NB_CYCLES) UsersDataBucket.UsersDataBucket(indexUserDataPrincipal);
    //                                     let principal = Principal.fromActor(aktor);

    //                                     Map.add(bucketsUserDataPrincipals, Principal.compare, Principal.fromActor(aktor), ());

    //                                     principal
    //                                 } catch (e) {
    //                                     return #err("Cannot create new bucket: " # Error.message(e));
    //                                 };
    //                             } else if ( caller == indexTodosPrincipal ) {
    //                                 try {
    //                                     let aktor       = await (with cycles = Configs.Consts.NEW_BUCKET_NB_CYCLES) TodosBucket.TodosBucket(indexTodosPrincipal);
    //                                     let principal   = Principal.fromActor(aktor);

    //                                     Map.add(bucketsTodosPrincipals, Principal.compare, Principal.fromActor(aktor), ());

    //                                     principal
    //                                 } catch (e) {
    //                                     return #err("Cannot create new bucket: " # Error.message(e));
    //                                 };
    //                             } else if ( caller == indexGroupsPrincipal ) {
    //                                 try {
    //                                     let aktor       = await (with cycles = Configs.Consts.NEW_BUCKET_NB_CYCLES) GroupsBucket.GroupsBucket(indexGroupsPrincipal);
    //                                     let principal   = Principal.fromActor(aktor);

    //                                     Map.add(bucketsGroupsPrincipals, Principal.compare, Principal.fromActor(aktor), ());

    //                                     principal
    //                                 } catch (e) {
    //                                     return #err("Cannot create new bucket: " # Error.message(e));
    //                                 }
    //                             }; 

    //     #ok(bucketprincipal)
    // };
};