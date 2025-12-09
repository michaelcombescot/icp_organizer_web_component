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
import List "mo:core/List";
import Runtime "mo:core/Runtime";
import CanistersKinds "../shared/canistersKinds";
import TodosUsersIndex "../modules/todos/canisters/users/todosUsersIndex";
import TodosUsersBucket "../modules/todos/canisters/users/todosUsersBucket";
import TodosGroupsBucket "../modules/todos/canisters/groups/todosGroupsBucket";
import TodosGroupsIndex "../modules/todos/canisters/groups/todosGroupsIndex";
import TodosRegistry "todosRegistry";
import CanistersMap "../shared/canistersMap";

// The coordinator is the main entry point to launch the application.
// Launching the coordinator will create all necessary buckets and indexes, it's the ONLY entry point, everything else is dynamically created.
// It will have several missions:
// - create buckets and indexes
// - top indexes and canisters with cycles
// - check if there are free buckets in the bucket pool.The bucket pool is here for the different indexes to pick new active buckets when a buckets return a signal it's full.
//   The goal of this system is to be able to have canisters knowed by all indexes before the moment they are used.
shared ({ caller = owner }) persistent actor class Coordinator(todosRegistryPrincipal: Principal) = this {
    /////////////
    // CONFIGS //
    /////////////

    let TIMER_INTERVAL_NS           = 20_000_000_000;

    let TOPPING_THRESHOLD           = 1_000_000_000_000;
    let TOPPING_AMOUNT_BUCKETS      = 1_000_000_000_000;
    let TOPPING_AMOUNT_INDEXES      = 1_000_000_000_000;
    let TOPPING_AMOUNT_REGISTRY     = 1_000_000_000_000;

    let NEW_BUCKET_NB_CYCLES        = 2_000_000_000_000;
    let NEW_INDEX_NB_CYCLES         = 2_000_000_000_000;

    ////////////
    // ERRORS //
    ////////////

    type APIErrors = {
        #errorSendPrincipalToCanister: { targetPrincipal: Principal; targetKind: CanistersKinds.CanisterKind; canisterKind: CanistersKinds.CanisterKind; canisterPrincipal: Principal };
    };

    var listAPIErrors = List.empty<APIErrors>();

    ////////////
    // MEMORY //
    ////////////

    let memoryCanisters = CanistersMap.arrayToCanistersMap([ (#registries(#todosRegistry), [todosRegistryPrincipal]) ]);

    let memoryFreeBuckets   = Map.empty<CanistersKinds.BucketKind, List.List<Principal>>();

    ////////////
    // SYSTEM //
    ////////////

    type inspectParams = {
        arg : Blob;
        caller : Principal;
        msg : {
            #handlerUpgradeCanisterKind : () -> {code : Blob; nature : CanistersKinds.CanisterKind};
            #handlerAddIndex : () -> { indexKind: CanistersKinds.IndexKind };
            #handlerGiveFreeBucket : () -> {bucketKind : CanistersKinds.BucketKind};
        }
    };

    system func inspect(params: inspectParams) : Bool {
        switch ( params.msg ) {
            case (#handlerAddIndex(_))          params.caller != owner;
            case (#handlerUpgradeCanisterKind(_))   params.caller != owner;
            case (#handlerGiveFreeBucket(_))    CanistersMap.isPrincipalAnIndex(memoryCanisters, params.caller) ;
        }
    };

    system func timer(setGlobalTimer : (Nat64) -> ()) : async () {
        await helperTopCanisters();
        await helperCreateNewFreeBuckets();
        await helperHandleErrors();

        setGlobalTimer(Nat64.fromIntWrap(Time.now()) + Nat64.fromNat(TIMER_INTERVAL_NS));
    };

    /////////
    // API //
    /////////

    
    /// ADMIN ///

    // upgrade a canister of a specific type, used in cli with the command (replace with the right canister path):
    // - dfx canister call coordinator handlerUpgradeCanister '(#buckettype, blob "'$(hexdump -ve '1/1 "\\\\%02x"' .dfx/local/canisters/organizerUsersDataBucket/organizerUsersDataBucket.wasm)'")'
    public shared func handlerUpgradeCanisterKind({ nature : CanistersKinds.CanisterKind; code: Blob.Blob }) : async () {
        let ?canistersMap = Map.get(memoryCanisters, CanistersKinds.compareCanisterKinds, nature) else Runtime.trap("No canisters of type " # debug_show(nature) # " found");

        for ( canisterPrincipal in Map.keys(canistersMap) ) {
            try {
                ignore IC.ic.install_code({ mode = #upgrade(null); canister_id = canisterPrincipal; wasm_module = code; arg = to_candid((Principal.anonymous())); sender_canister_version = null; });                   
            } catch (e) {
                Debug.print("Cannot upgrade bucket, error: " # Error.message(e));
            };
        };
    };

    // add a new index to the index list
    public shared func handlerAddIndex({ indexKind: CanistersKinds.IndexKind }) : async () {
        try {
            ignore helperCreateCanister({ canisterType = #indexes(indexKind) });
        } catch (e) {
            Debug.print("Cannot create index, error: " # Error.message(e));
        }
    };

    /// API FOR INDEXES ///

    public shared func handlerGiveFreeBucket({ bucketKind: CanistersKinds.BucketKind }) : async Result.Result<Principal, Text> {
        let ?list = Map.get(memoryFreeBuckets, CanistersKinds.compareBucketsKinds, bucketKind) else return #err("No free buckets of type " # debug_show(bucketKind) # " found");

        switch ( List.removeLast(list) ) {
            case (?principal) #ok(principal);
            case null #err("List of free buckets is empty for type: " # debug_show(bucketKind));
        }
    };

    /////////////
    // HELPERS //
    /////////////

    func helperCreateCanister({ canisterType : CanistersKinds.CanisterKind }) : async () {
        var newPrincipal: ?Principal = null;

        try {
            switch (canisterType) {
                case (#registries(_)) (); // registry is never created by the helper
                case (#indexes(indexKind)) {
                    switch (indexKind) {
                        case (#todosUsersIndex)     newPrincipal := ?Principal.fromActor(await (with cycles = NEW_INDEX_NB_CYCLES) TodosUsersIndex.TodosUsersIndex());
                        case (#todosGroupsIndex)    newPrincipal := ?Principal.fromActor(await (with cycles = NEW_INDEX_NB_CYCLES) TodosGroupsIndex.TodosGroupsIndex());
                    };
                };
                case (#buckets(bucketKind)) {
                    switch (bucketKind) {
                        case (#todos(todoBucketKind)) {
                            switch (todoBucketKind) {
                                case (#todosUsersBucket)  newPrincipal := ?Principal.fromActor(await (with cycles = NEW_BUCKET_NB_CYCLES) TodosUsersBucket.TodosUsersBucket());
                                case (#todosGroupsBucket) newPrincipal := ?Principal.fromActor(await (with cycles = NEW_BUCKET_NB_CYCLES) TodosGroupsBucket.TodosGroupsBucket());
                            };
                        };
                    };

                    let ?newPrincipalValue = newPrincipal else { Debug.print("newPrincipal has not been set"); return };

                    switch ( Map.get(memoryFreeBuckets, CanistersKinds.compareBucketsKinds, bucketKind) ) {
                        case null Map.add(memoryFreeBuckets, CanistersKinds.compareBucketsKinds, bucketKind, List.singleton(newPrincipalValue));
                        case (?list) List.add(list, newPrincipalValue);
                    };
                };
            };
        } catch (e) {
            Debug.print("Cannot create canister of type " # debug_show(canisterType) # ", error: " # Error.message(e));
        };

        switch (newPrincipal) {
            case null (); // TODO add error to retry
            case (?newPrincipalValue) {
                // add canister to canistersMap
                CanistersMap.addCanisterToMap({ map = memoryCanisters; canisterPrincipal = newPrincipalValue; canisterKind = canisterType });

                // send the new principal to all canisters
                for ( (kind, typeMap) in Map.entries(memoryCanisters) ) {
                    for ( canisterPrincipal in Map.keys(typeMap) ) {
                        await helperSendPrincipalToCanister({ targetPrincipal = canisterPrincipal; targetKind = kind; canisterPrincipal = newPrincipalValue; canisterKind = canisterType });
                    };
                };
            };
        };
    };

    func helperSendPrincipalToCanister({ targetPrincipal: Principal; targetKind: CanistersKinds.CanisterKind; canisterPrincipal: Principal; canisterKind : CanistersKinds.CanisterKind; }) : async () {
        try {
            switch (targetKind) {
                case (#registries(regisryKind)) {
                    switch (regisryKind) {
                        case (#todosRegistry)  await (actor(Principal.toText(targetPrincipal)) : TodosRegistry.TodosRegistry).systemAddCanisterToMap({ canisterPrincipal = canisterPrincipal; canisterKind = canisterKind });
                    };
                };
                case (#indexes(indexKind)) {
                    switch (indexKind) {
                        case (#todosUsersIndex)     await (actor(Principal.toText(targetPrincipal)) : TodosUsersIndex.TodosUsersIndex).systemAddCanisterToMap({ canisterPrincipal = canisterPrincipal; canisterKind = canisterKind });
                        case (#todosGroupsIndex)    await (actor(Principal.toText(targetPrincipal)) : TodosGroupsIndex.TodosGroupsIndex).systemAddCanisterToMap({ canisterPrincipal = canisterPrincipal; canisterKind = canisterKind });
                    };
                };
                case (#buckets(bucketKind)) {
                    switch (bucketKind) {
                        case (#todos(todoBucketKind)) {
                            switch (todoBucketKind) {
                                case (#todosUsersBucket)  await (actor(Principal.toText(targetPrincipal)) : TodosUsersBucket.TodosUsersBucket).systemAddCanisterToMap({ canisterPrincipal = canisterPrincipal; canisterKind = canisterKind });
                                case (#todosGroupsBucket) await (actor(Principal.toText(targetPrincipal)) : TodosGroupsBucket.TodosGroupsBucket).systemAddCanisterToMap({ canisterPrincipal = canisterPrincipal; canisterKind = canisterKind });
                            };
                        };
                    };
                };
            }
        } catch (e) {
            Debug.print("Cannot send principal to canister, error: " # Error.message(e));
            List.add(listAPIErrors, #errorSendPrincipalToCanister({ targetPrincipal = targetPrincipal; targetKind = targetKind; canisterKind = canisterKind; canisterPrincipal = canisterPrincipal }));
        }
    };

    func helperTopCanisters() : async () {
        for ( (nature, typeMap) in Map.entries(memoryCanisters) ) {
            let toppingAmount = switch (nature) {
                                    case (#indexes(_)) TOPPING_AMOUNT_INDEXES;                        
                                    case (#buckets(_)) TOPPING_AMOUNT_BUCKETS;                
                                    case (#registries(_)) TOPPING_AMOUNT_REGISTRY;
                                };


            for ( canisterPrincipal in Map.keys(typeMap) ) { 
                let status = await IC.ic.canister_status({ canister_id = canisterPrincipal });
                if (status.cycles < TOPPING_THRESHOLD) {
                    Debug.print("Bucket low on cycles, requesting top-up for " # Principal.toText(canisterPrincipal) # "with " # Nat.toText(toppingAmount) # " cycles");

                    try {
                        ignore (with cycles = toppingAmount) IC.ic.deposit_cycles({ canister_id = canisterPrincipal });
                    } catch (e) {
                        Debug.print("Error while topping up bucket " # Principal.toText(canisterPrincipal) # ": " # Error.message(e));
                    };
                };
            };
        };
    };

    func helperCreateNewFreeBuckets() : async () {
        for ( (nature, typeMap) in Map.entries(memoryCanisters) ) {
            switch (nature) {
                case (#indexes(_) or #registries(_)) ();
                case (#buckets(bucketKind)) {
                    let nbFreeBuckets = switch ( Map.get(memoryFreeBuckets, CanistersKinds.compareBucketsKinds, bucketKind) ) {
                                            case null 0;
                                            case (?list) List.size(list);
                                        };

                    let numberOfIndexes =   switch (nature) {
                                                case (#indexes(_)) Map.size(typeMap);
                                                case _ 0;
                                            };

                    var i = 0;
                    while ( i + nbFreeBuckets <= numberOfIndexes) {
                        
                        i := i + 1;
                    };
                        
                };
            };
        };
    };

    func helperHandleErrors() : async () {
        // api errors retry
        let tempList = List.empty<APIErrors>();
        for ( error in List.values(listAPIErrors) ) {
            switch (error) {
                case (#errorSendPrincipalToCanister(params)) {
                    try {
                        await helperSendPrincipalToCanister(params);
                    } catch (e) {
                        Debug.print("Cannot send principal to canister, error: " # Error.message(e));
                        List.add(tempList, #errorSendPrincipalToCanister(params));
                    };
                };
            };
        };

        listAPIErrors := tempList;
    };
};