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
import TodosIndex "../modules/todos/canisters/todosIndex";
import TodosGroupsBucket "../modules/todos/canisters/todosGroupsBucket";
import TodosUsersBucket "../modules/todos/canisters/todosUsersBucket";
import TodosRegistry "../modules/todos/canisters/todosRegistry";
import CanistersMap "../shared/canistersMap";
import Timer "mo:core/Timer";
import Array "mo:core/Array";
import CanistersVirtualArray "../shared/canistersVirtualArray";

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

    let ERR_NO_FREE_BUCKET = "ERR_NO_FREE_BUCKET";

    type APIErrors = {
        #errorSendPrincipalsToCanister: { targetPrincipal: Principal; targetKind: CanistersKinds.CanisterKind; canisterKind: CanistersKinds.CanisterKind; canistersPrincipals: [Principal] };
    };

    var listAPIErrors = List.empty<APIErrors>();

    ////////////
    // MEMORY //
    ////////////

    let memoryCanisters = CanistersMap.arrayToCanistersMap([ (#todosRegistry, [todosRegistryPrincipal]) ]);

    let memoryFreeBuckets  = Map.empty<CanistersKinds.CanisterKind, List.List<Principal>>();

    // this is the array used to map users principal to their buckets.
    // It use virtual slots in a predefined size array. All slots are initialized with a single bucket to start.
    // When the count of users increase, some slots will be set with new buckets, and the load will be spreaded.
    var memoryUsersBuckets: CanistersVirtualArray.CanistersVirtualArray = [];

    ////////////
    // SYSTEM //
    ////////////

    // init the canister
    ignore Timer.setTimer<system>(
        #seconds(0),
        func() : async () {
            if ( memoryUsersBuckets.size() == 0 ) {
                let principal = Principal.fromActor(await (with cycles = NEW_BUCKET_NB_CYCLES) TodosUsersBucket.TodosUsersBucket());
                CanistersMap.addCanistersToMap({ map = memoryCanisters; canistersPrincipals = [principal]; canisterKind = #todosUsersBucket });
                memoryUsersBuckets := CanistersVirtualArray.newCanistersVirtualArray(1, principal);
            };         
        }
    );

    type inspectParams = {
        arg : Blob;
        caller : Principal;
        msg : {
            #handlerUpgradeCanisterKind : () -> {code : Blob; nature : CanistersKinds.CanisterKind};
            #handlerAddIndex : () -> (indexKind: CanistersKinds.CanisterKind);
            #handlerGetCanisters: () -> ();

            #handlerGiveFreeBucket : () -> (bucketKind: CanistersKinds.CanisterKind);
        }
    };

    system func inspect(params: inspectParams) : Bool {
        switch ( params.msg ) {
            case (#handlerAddIndex(_))              params.caller == owner;
            case (#handlerUpgradeCanisterKind(_))   params.caller == owner;
            case (#handlerGetCanisters(_))          params.caller == owner;

            case (#handlerGiveFreeBucket(_))        CanistersMap.isPrincipalInKind(memoryCanisters, params.caller, #todosIndex) ;
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
    public shared func handlerAddIndex(indexKind: CanistersKinds.CanisterKind) : async Result.Result<(), Text> {
        switch indexKind {
            case (#todosIndex) ();
            case (#todosRegistry or #todosUsersBucket or #todosGroupsBucket) return #err("Cannot add index of type " # debug_show(indexKind));
        };

        try {
            await helperCreateCanister(indexKind);
            #ok
        } catch (e) {
            #err("Cannot create index, error: " # Error.message(e))
        }
    };

    /// API FOR INDEXES ///

    public shared func handlerGiveFreeBucket(bucketKind: CanistersKinds.CanisterKind) : async Result.Result<Principal, Text> {
        switch bucketKind {
            case (#todosGroupsBucket or #todosUsersBucket) ();
            case (#todosRegistry or #todosIndex) return #err("Cannot give free bucket of type " # debug_show(bucketKind));
        };

        let ?list = Map.get(memoryFreeBuckets, CanistersKinds.compareCanisterKinds, bucketKind) else return #err("No free buckets of type " # debug_show(bucketKind) # " found");

        switch ( List.removeLast(list) ) {
            case (?principal) #ok(principal);
            case null #err(ERR_NO_FREE_BUCKET);
        }
    };

    /////////////
    // HELPERS //
    /////////////

    func helperCreateCanister(canisterType : CanistersKinds.CanisterKind) : async () {
        try {
            switch (canisterType) {
                case (#todosRegistry)   (); // registry is never created by the helper
                case (#todosIndex) {
                    // create the canister
                    let newPrincipal = Principal.fromActor(await (with cycles = NEW_INDEX_NB_CYCLES) TodosIndex.TodosIndex());

                    // save it in the memoryCanisters map
                    CanistersMap.addCanistersToMap({ map = memoryCanisters; canistersPrincipals = [newPrincipal]; canisterKind = #todosIndex });

                    // send it to all todos users buckets and todos buckets
                    ignore helperSendUserArrayToCanistersOfKind({ targetKind = #todosIndex; });
                    ignore helperSendPrincipalsToCanistersOfKind({ targetKind = #todosBucket; canisterKind = #todosIndex; canistersPrincipals  = [newPrincipal] });
                    ignore helperSendPrincipalsToCanistersOfKind({ targetKind = #todosUsersBucket; canisterKind = #todosIndex; canistersPrincipals  = [newPrincipal] });

                    // feed it with all necessary canisters principals
                    ignore helperSendCanistersKindToPrincipal({ targetKind = #todosIndex; targetPrincipal = newPrincipal; canisterKind = #todosIndex; });
                    ignore helperSendCanistersKindToPrincipal({ targetKind = #todosIndex; targetPrincipal = newPrincipal; canisterKind = #todosIndex; });
                };
                case (#todosUsersBucket) {
                    // create the canister
                    let newPrincipal = Principal.fromActor(await (with cycles = NEW_BUCKET_NB_CYCLES) TodosBucket.TodosBucket());

                    // save in the memoryUsersBuckets
                    CanistersMap.addCanistersToMap({ map = memoryCanisters; canistersPrincipals = [newPrincipal]; canisterKind = #todosUsersBucket });

                    // rebalance 
                    // TODO: handle a way to rebalance users buckets

                    // send it to all todos indexes
                    ignore helperSendUserArrayToCanistersOfKind({ targetKind = #todosIndex; });
                };
                case (#todosBucket) {
                    // create the canister
                    let newPrincipal = Principal.fromActor(await (with cycles = NEW_BUCKET_NB_CYCLES) TodosBucket.TodosBucket());

                    // save it in the memoryCanisters map
                    CanistersMap.addCanistersToMap({ map = memoryCanisters; canistersPrincipals = [newPrincipal]; canisterKind = #todosBucket });

                    // add it to free buckets list
                    switch ( Map.get(memoryFreeBuckets, CanistersKinds.compareCanisterKinds, canisterType) ) {
                        case null Map.add(memoryFreeBuckets, CanistersKinds.compareCanisterKinds, canisterType, List.singleton(newPrincipal));
                        case (?list) List.add(list, newPrincipal);
                    };

                    // send it to all todos users buckets and todos indexes
                    ignore helperSendPrincipalsToCanistersOfKind({ targetKind = #todosUsersBucket; canisterKind = #todosBucket; canistersPrincipals = [newPrincipal] });
                    ignore helperSendPrincipalsToCanistersOfKind({ targetKind = #todosIndex; canisterKind = #todosBucket; canistersPrincipals = [newPrincipal] });
                };
            };
        } catch (e) {
            Debug.print("Cannot create canister of type " # debug_show(canisterType) # ", error: " # Error.message(e));
        };
    };

    func helperSendPrincipalsToCanistersOfKind({ targetKind: CanistersKinds.CanisterKind; canisterKind : CanistersKinds.CanisterKind; canistersPrincipals: [Principal]; }) : async () {
        let ?map = Map.get(memoryCanisters, CanistersKinds.compareCanisterKinds, targetKind) else return;

        for ( targetPrincipal in Map.keys(map) ) {
            await helperSendPrincipalsToCanister({ targetPrincipal = targetPrincipal; targetKind = targetKind; canistersPrincipals = canistersPrincipals; canisterKind = canisterKind });
        } 
    };

    func helperSendCanistersKindToPrincipal({ targetKind: CanistersKinds.CanisterKind; targetPrincipal: Principal; canisterKind : CanistersKinds.CanisterKind; }) : async () {
        let ?map = Map.get(memoryCanisters, CanistersKinds.compareCanisterKinds, canisterKind) else return;

        await helperSendPrincipalsToCanister({ targetPrincipal = targetPrincipal; targetKind = targetKind; canistersPrincipals = Array.fromIter(Map.keys(map)); canisterKind = canisterKind });
    };

    func helperSendPrincipalsToCanister({ targetPrincipal: Principal; targetKind: CanistersKinds.CanisterKind; canistersPrincipals: [Principal]; canisterKind : CanistersKinds.CanisterKind; }) : async () {
        try {
            switch (targetKind) {
                case (#todosRegistry)   await (actor(Principal.toText(targetPrincipal)) : TodosRegistry.TodosRegistry).systemAddCanistersToMap({ canistersPrincipals = canistersPrincipals; canisterKind = canisterKind });
                case (#todosIndex)      await (actor(Principal.toText(targetPrincipal)) : TodosIndex.TodosIndex).systemAddCanistersToMap({ canistersPrincipals = canistersPrincipals; canisterKind = canisterKind });
                case (#todosGroupsBucket)     await (actor(Principal.toText(targetPrincipal)) : TodosGroupsBucket.TodosGroupsBucket).systemAddCanistersToMap({ canistersPrincipals = canistersPrincipals; canisterKind = canisterKind });
                case (#todosUsersBucket) await (actor(Principal.toText(targetPrincipal)) : TodosUsersBucket.TodosUsersBucket).systemAddCanistersToMap({ canistersPrincipals = canistersPrincipals; canisterKind = canisterKind });
            }
        } catch (e) {
            Debug.print("Cannot send principal to canister, error: " # Error.message(e));
            List.add(listAPIErrors, #errorSendPrincipalsToCanister({ targetPrincipal = targetPrincipal; targetKind = targetKind; canisterKind = canisterKind; canistersPrincipals = canistersPrincipals }));
        }
    };

    func helperSendUserArrayToCanistersOfKind({ targetKind: CanistersKinds.CanisterKind; }) : async () {
        let ?map = Map.get(memoryCanisters, CanistersKinds.compareCanisterKinds, targetKind) else return;

        switch ( targetKind ) {
            case (#todosRegistry or #todosBucket or #todosUsersBucket) ();
            case (#todosIndex) {
                for ( targetPrincipal in Map.keys(map) ) {
                    try {
                        await (actor(Principal.toText(targetPrincipal)) : TodosIndex.TodosIndex).systemUpdateUsersBucketsArray();
                    } catch (e) {
                        Debug.print("Cannot send user array to canister, error: " # Error.message(e));
                    };
                };
            };
        };
    };

    func helperTopCanisters() : async () {
        for ( (nature, typeMap) in Map.entries(memoryCanisters) ) {
            let toppingAmount = switch (nature) {
                                    case (#todosRegistry)       TOPPING_AMOUNT_REGISTRY;
                                    case (#todosIndex)          TOPPING_AMOUNT_INDEXES;                        
                                    case (#todosBucket)         TOPPING_AMOUNT_BUCKETS; 
                                    case (#todosUsersBucket)    TOPPING_AMOUNT_BUCKETS;               
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
        label l for ( (kind, listPrincipals) in Map.entries(memoryFreeBuckets) ) {
            let nbIndexes = switch (kind) {
                                case (#todosIndex or #todosRegistry or #todosUsersBucket) continue l;
                                case (#todosBucket) CanistersMap.getPrincipalsForKind(memoryCanisters, #todosIndex).size();
                            };
            let nbBuckets = List.size(listPrincipals);
                                    
            var i = 0;
            while ( i + nbBuckets <= nbIndexes) {
                ignore helperCreateCanister(kind);

                i := i + 1;
            };
        };
    };

    func helperHandleErrors() : async () {
        // api errors retry
        let tempList = List.empty<APIErrors>();
        for ( error in List.values(listAPIErrors) ) {
            switch (error) {
                case (#errorSendPrincipalsToCanister(params)) {
                    try {
                        await helperSendPrincipalsToCanister(params);
                    } catch (e) {
                        Debug.print("Cannot send principal to canister, error: " # Error.message(e));
                        List.add(tempList, #errorSendPrincipalsToCanister(params));
                    };
                };
            };
        };

        listAPIErrors := tempList;
    };
};