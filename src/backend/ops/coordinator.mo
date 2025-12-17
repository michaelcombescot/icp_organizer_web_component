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
import MainIndex "../canisters/mainIndex";
import GroupsBucket "../canisters/groupsBucket";
import UsersBucket "../canisters/usersBucket";
import IndexesRegistry "indexesRegistry";
import CanistersMap "../shared/canistersMap";
import Timer "mo:core/Timer";
import Array "mo:core/Array";

// The coordinator is the main entry point to launch the application.
// Launching the coordinator will create all necessary buckets and indexes, it's the ONLY entry point, everything else is dynamically created.
// It will have several missions:
// - create buckets and indexes
// - top indexes and canisters with cycles
// - check if there are free buckets in the bucket pool.The bucket pool is here for the different indexes to pick new active buckets when a buckets return a signal it's full.
//   The goal of this system is to be able to have canisters knowed by all indexes before the moment they are used.
shared ({ caller = owner }) persistent actor class Coordinator(indexesRegistryPrincipal: Principal) = this {
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

    let memoryCanisters = CanistersMap.arrayToCanistersMap([ (#registries(#indexesRegistry), [indexesRegistryPrincipal]) ]);

    let memoryFreeBuckets  = Map.empty<CanistersKinds.CanisterKind, List.List<Principal>>();

    var memoryUsersMapping: [Principal] = [];

    ////////////
    // SYSTEM //
    ////////////

    type inspectParams = {
        arg : Blob;
        caller : Principal;
        msg : {
            #handlerUpgradeCanisterKind : () -> {code : Blob; nature : CanistersKinds.CanisterKind};
            #handlerAddIndex : () -> (indexKind: CanistersKinds.Indexes);
            #handlerGiveFreeBucket : () -> (bucketKind: CanistersKinds.Buckets);
        }
    };

    system func inspect(params: inspectParams) : Bool {
        switch ( params.msg ) {
            case (#handlerAddIndex(_))              params.caller == owner;
            case (#handlerUpgradeCanisterKind(_))   params.caller == owner;
            case (#handlerGiveFreeBucket(_))        CanistersMap.isPrincipalInKind(memoryCanisters, params.caller, #indexes(#mainIndex)) ;
        }
    };

    system func timer(setGlobalTimer : (Nat64) -> ()) : async () {
        await helperTopCanisters();
        await helperCreateNewFreeBuckets();
        await helperHandleErrors();

        setGlobalTimer(Nat64.fromIntWrap(Time.now()) + Nat64.fromNat(TIMER_INTERVAL_NS));
    };

    // initialization
    func initUsersMapping() : async () {
        if ( memoryUsersMapping.size() == 0 ) {
            try { 
                let newPrincipal = Principal.fromActor(await (with cycles = NEW_BUCKET_NB_CYCLES) UsersBucket.UsersBucket());
                memoryUsersMapping := Array.tabulate<Principal>(1000, func(i) = newPrincipal);
            } catch (e) {
                Debug.print("Cannot create user mapping first bucket, error: " # Error.message(e));
                ignore Timer.setTimer<system>(#seconds(1), initUsersMapping);
            };
        };
    };

    ignore Timer.setTimer<system>(
        #seconds(0),
        initUsersMapping
    );

    /////////
    // API //
    /////////

    /// ADMIN ///

    // upgrade a canister of a specific type, used in cli with the command (replace with the right canister path):
    // - dfx canister call coordinator handlerUpgradeCanister '(#buckettype, blob "'$(hexdump -ve '1/1 "\\\\%02x"' .dfx/local/canisters/organizerUsersDataBucket/organizerUsersDataBucket.wasm)'")'
    public shared func handlerUpgradeCanisterKind({ nature : CanistersKinds.CanisterKind; code: Blob.Blob }) : async () {
        let ?canistersMap = memoryCanisters.get(CanistersKinds.compareCanisterKinds, nature) else Runtime.trap("No canisters of type " # debug_show(nature) # " found");

        for ( canisterPrincipal in Map.keys(canistersMap) ) {
            try {
                ignore IC.ic.install_code({ mode = #upgrade(null); canister_id = canisterPrincipal; wasm_module = code; arg = to_candid((Principal.anonymous())); sender_canister_version = null; });                   
            } catch (e) {
                Debug.print("Cannot upgrade bucket, error: " # Error.message(e));
            };
        };
    };

    // add a new index to the index list
    public shared func handlerAddIndex(indexKind: CanistersKinds.Indexes) : async Result.Result<(), Text> {
        try {
            await helperCreateCanister(#indexes(indexKind));
            #ok
        } catch (e) {
            #err("Cannot create index, error: " # Error.message(e))
        }
    };

    /// API FOR INDEXES ///

    public shared func handlerGiveFreeBucket(bucketKind: CanistersKinds.Buckets) : async Result.Result<Principal, Text> {
        let ?list = memoryFreeBuckets.get(CanistersKinds.compareCanisterKinds, #buckets(bucketKind)) else return #err("No free buckets of type " # debug_show(bucketKind) # " found");

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
                case (#registries(_))   (); // registry is never created by the helper
                case (#indexes(indexKind)) {
                    switch (indexKind) {
                        case (#mainIndex) {
                            // create the canister
                            let newPrincipal = Principal.fromActor(await (with cycles = NEW_INDEX_NB_CYCLES) MainIndex.MainIndex());
                            // save it in the memoryCanisters map
                            CanistersMap.addCanistersToMap({ map = memoryCanisters; canistersPrincipals = [newPrincipal]; canisterKind = #indexes(#mainIndex) });
                            // send it to all todos buckets
                            ignore helperSendPrincipalsToCanistersOfKind({ targetKind = #buckets(#groupsBucket); canisterKind = #indexes(#mainIndex); canistersPrincipals  = [newPrincipal] });
                            ignore helperSendPrincipalsToCanistersOfKind({ targetKind = #buckets(#usersBucket); canisterKind = #indexes(#mainIndex); canistersPrincipals  = [newPrincipal] });
                            // feed it with all necessary canisters principals
                            ignore helperSendCanistersKindToPrincipal({ targetKind = #indexes(#mainIndex); targetPrincipal = newPrincipal; canisterKind = #buckets(#groupsBucket); });
                        };
                    };
                };
                case (#buckets(bucketKind)) {
                    switch (bucketKind) {
                        case (#usersBucket) {
                            // create the canister
                            let newPrincipal = Principal.fromActor(await (with cycles = NEW_BUCKET_NB_CYCLES) UsersBucket.UsersBucket());
                            // save in the memoryUsersBuckets
                            CanistersMap.addCanistersToMap({ map = memoryCanisters; canistersPrincipals = [newPrincipal]; canisterKind = #buckets(#usersBucket) });
                            // add it to free buckets list
                            switch ( Map.get(memoryFreeBuckets, CanistersKinds.compareCanisterKinds, canisterType) ) {
                                case null Map.add(memoryFreeBuckets, CanistersKinds.compareCanisterKinds, canisterType, List.singleton(newPrincipal));
                                case (?list) List.add(list, newPrincipal);
                            };

                            // send it to all relevant canisters
                            ignore helperSendPrincipalsToCanistersOfKind({ targetKind = #indexes(#mainIndex); canisterKind = #buckets(#usersBucket); canistersPrincipals = [newPrincipal] });
                            ignore helperSendPrincipalsToCanistersOfKind({ targetKind = #buckets(#groupsBucket); canisterKind = #buckets(#usersBucket); canistersPrincipals = [newPrincipal] });
                        };
                        case (#groupsBucket) {
                            // create the canister
                            let newPrincipal = Principal.fromActor(await (with cycles = NEW_BUCKET_NB_CYCLES) GroupsBucket.GroupsBucket());
                            // save it in the memoryCanisters map
                            CanistersMap.addCanistersToMap({ map = memoryCanisters; canistersPrincipals = [newPrincipal]; canisterKind = #buckets(#groupsBucket) });
                            // add it to free buckets list
                            switch ( Map.get(memoryFreeBuckets, CanistersKinds.compareCanisterKinds, canisterType) ) {
                                case null Map.add(memoryFreeBuckets, CanistersKinds.compareCanisterKinds, canisterType, List.singleton(newPrincipal));
                                case (?list) List.add(list, newPrincipal);
                            };

                            // send it to all relevant canisters
                            ignore helperSendPrincipalsToCanistersOfKind({ targetKind = #indexes(#mainIndex); canisterKind = #buckets(#groupsBucket); canistersPrincipals = [newPrincipal] });
                            ignore helperSendPrincipalsToCanistersOfKind({ targetKind = #buckets(#usersBucket); canisterKind = #buckets(#groupsBucket); canistersPrincipals = [newPrincipal] });
                        };
                    };
                };
            };
        } catch (e) {
            Debug.print("Cannot create canister of type " # debug_show(canisterType) # ", error: " # Error.message(e));
        };
    };

    // send an array of principals to all canisters of a specific kind
    func helperSendPrincipalsToCanistersOfKind({ targetKind: CanistersKinds.CanisterKind; canisterKind : CanistersKinds.CanisterKind; canistersPrincipals: [Principal]; }) : async () {
        let ?map = memoryCanisters.get(CanistersKinds.compareCanisterKinds, targetKind) else return;

        for ( targetPrincipal in Map.keys(map) ) {
            await helperSendPrincipalsToCanister({ targetPrincipal = targetPrincipal; targetKind = targetKind; canistersPrincipals = canistersPrincipals; canisterKind = canisterKind });
        } 
    };

    // send all buckets of a specific kind to a specific principal
    func helperSendCanistersKindToPrincipal({ targetKind: CanistersKinds.CanisterKind; targetPrincipal: Principal; canisterKind : CanistersKinds.CanisterKind; }) : async () {
        let ?map = memoryCanisters.get(CanistersKinds.compareCanisterKinds, canisterKind) else return;

        await helperSendPrincipalsToCanister({ targetPrincipal = targetPrincipal; targetKind = targetKind; canistersPrincipals = Array.fromIter(Map.keys(map)); canisterKind = canisterKind });
    };

    // send a specific list of principals to a specific canister
    func helperSendPrincipalsToCanister({ targetPrincipal: Principal; targetKind: CanistersKinds.CanisterKind; canistersPrincipals: [Principal]; canisterKind : CanistersKinds.CanisterKind; }) : async () {
        try {
            switch (targetKind) {
                case (#registries(registrykind)) {
                    switch (registrykind) {
                        case (#indexesRegistry) await (actor(Principal.toText(targetPrincipal)) : IndexesRegistry.IndexesRegistry).systemAddCanistersToMap({ canistersPrincipals = canistersPrincipals; canisterKind = canisterKind }); 
                    };
                };
                case (#indexes(indexKind)) {
                    switch (indexKind) {
                        case (#mainIndex) await (actor(Principal.toText(targetPrincipal)) : MainIndex.MainIndex).systemAddCanistersToMap({ canistersPrincipals = canistersPrincipals; canisterKind = canisterKind });
                    };
                };
                case (#buckets(bucketKind)) {
                    switch (bucketKind) {
                        case (#usersBucket)     await (actor(Principal.toText(targetPrincipal)) : UsersBucket.UsersBucket).systemAddCanistersToMap({ canistersPrincipals = canistersPrincipals; canisterKind = canisterKind });
                        case (#groupsBucket)    await (actor(Principal.toText(targetPrincipal)) : GroupsBucket.GroupsBucket).systemAddCanistersToMap({ canistersPrincipals = canistersPrincipals; canisterKind = canisterKind });
                    };
                };
            };
        } catch (e) {
            Debug.print("Cannot send principal to canister, error: " # Error.message(e));
            listAPIErrors.add(#errorSendPrincipalsToCanister({ targetPrincipal = targetPrincipal; targetKind = targetKind; canisterKind = canisterKind; canistersPrincipals = canistersPrincipals }));
        }
    };

    // send principals to canisters of kind
    

    // recharge numbers of cycles 
    func helperTopCanisters() : async () {
        for ( (nature, typeMap) in Map.entries(memoryCanisters) ) {
            let toppingAmount = switch (nature) {
                                    case (#registries(_))    TOPPING_AMOUNT_REGISTRY;
                                    case (#indexes(_))       TOPPING_AMOUNT_INDEXES;
                                    case (#buckets(_))       TOPPING_AMOUNT_BUCKETS;
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

    // create new free buckets, free buckets are the buckets precreated and put in a pool to be fetched when needed by indexes
    func helperCreateNewFreeBuckets() : async () {
        label l for ( (kind, listPrincipals) in memoryFreeBuckets.entries() ) {
            switch (kind) {
                case (#registries(_)) continue l;
                case (#indexes(_)) continue l;
                case (#buckets(bucketKind)) {
                    var nbIndexes = 0;
                    var nbBuckets = 0;
                    var missingBuckets = 0;

                    switch (bucketKind) {
                        case (#groupsBucket) {
                            nbIndexes := CanistersMap.getPrincipalsForKind(memoryCanisters, #indexes(#mainIndex)).size();
                            nbBuckets := listPrincipals.size();
                            missingBuckets := nbIndexes - nbBuckets;
                        };
                        case (#usersBucket) {
                            nbIndexes := CanistersMap.getPrincipalsForKind(memoryCanisters, #indexes(#mainIndex)).size();
                            nbBuckets := listPrincipals.size();
                            missingBuckets := 1;
                        };
                    };
                                            
                    while ( missingBuckets != 0 ) {
                        ignore helperCreateCanister(kind);
                        missingBuckets -= 1;
                    }; 
                };
            };
        };
    };

    // handle errors which needs to be retried
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
                        tempList.add(#errorSendPrincipalsToCanister(params));
                    };
                };
            };
        };

        listAPIErrors := tempList;
    };
};