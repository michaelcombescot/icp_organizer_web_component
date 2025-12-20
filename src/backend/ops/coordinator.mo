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

    type APIErrors = {
        #errSendingIndexToIndexesRegistry: { indexPrincipal: Principal; indexKind: CanistersKinds.IndexesKind };
    };

    var apiErrorsRetryList = List.empty<APIErrors>();

    ////////////
    // MEMORY //
    ////////////

    let memoryCanisters = Map.singleton<CanistersKinds.CanistersKind, Map.Map<Principal, ()>>(#static(#registries(#indexesRegistry)), Map.singleton(indexesRegistryPrincipal, ()));

    var memoryUsersMapping: [Principal] = [];

    let allowedCanisters = Map.empty<Principal, ()>();

    ////////////
    // SYSTEM //
    ////////////

    type inspectParams = {
        arg : Blob;
        caller : Principal;
        msg : {
            #handlerUpgradeCanisterKind : () -> (nature: CanistersKinds.CanistersKind, wasmModule: Blob.Blob);
            #handlerAddIndex : () -> (indexKind: CanistersKinds.IndexesKind);
            #handlerGiveNewBucket : () -> (bucketKind: CanistersKinds.BucketsKind);
            #handlerIsLegitCanister : () -> (canisterPrincipal: Principal);
        }
    };

    system func inspect(params: inspectParams) : Bool {
        switch ( params.msg ) {
            case (#handlerUpgradeCanisterKind(_))   params.caller == owner;
            case (#handlerAddIndex(_))              params.caller == owner;
            case (#handlerGiveNewBucket(_))         allowedCanisters.containsKey(params.caller);
            case (#handlerIsLegitCanister(_))       allowedCanisters.containsKey(params.caller);
        }
    };

    system func timer(setGlobalTimer : (Nat64) -> ()) : async () {
        await helperTopCanisters();
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
    public shared func handlerUpgradeCanisterKind(nature : CanistersKinds.CanistersKind, wasmModule: Blob.Blob) : async () {
        let ?canistersMap = memoryCanisters.get(CanistersKinds.compareCanistersKinds, nature) else Runtime.trap("No canisters of type " # debug_show(nature) # " found");

        for ( canisterPrincipal in Map.keys(canistersMap) ) {
            try {
                ignore IC.ic.install_code({ mode = #upgrade(null); canister_id = canisterPrincipal; wasm_module = wasmModule; arg = to_candid((Principal.anonymous())); sender_canister_version = null; });                 
                Debug.print("Upgraded canister " # Principal.toText(canisterPrincipal));
            } catch (e) {
                Debug.print("Cannot upgrade bucket, error: " # Error.message(e));
            };
        };
    };

    // add a new index to the index list
    public shared func handlerAddIndex(indexKind: CanistersKinds.IndexesKind) : async Result.Result<Principal, Text> {
        await helperCreateCanister(#indexes(indexKind))
    };

    // used by indexes to request a new bucket to save data on creation
    public shared func handlerGiveNewBucket(bucketKind: CanistersKinds.BucketsKind) : async Result.Result<Principal, Text> {
        await helperCreateCanister(#buckets(bucketKind))
    };

    // check if a specific canister belongs to the app
    public query func handlerIsLegitCanister(canisterPrincipal: Principal) : async Bool {
        let ?_ = allowedCanisters.get(canisterPrincipal) else return false;
        true
    };

    /////////////
    // HELPERS //
    /////////////

    func helperCreateCanister(canisterType : CanistersKinds.DynamicsKind) : async Result.Result<Principal, Text> {
        try {
            let newPrincipal =  switch (canisterType) {
                                    case (#indexes(indexKind)) {
                                        let newPrincipal =  switch (indexKind) {
                                                                case (#mainIndex) Principal.fromActor(await (with cycles = NEW_INDEX_NB_CYCLES) MainIndex.MainIndex());
                                                            };

                                        ignore helperSendIndexToIndexesRegistry(newPrincipal, indexKind);
                                        newPrincipal
                                    };
                                    case (#buckets(bucketKind)) {
                                        switch (bucketKind) {
                                            case (#usersBucket) Principal.fromActor(await (with cycles = NEW_BUCKET_NB_CYCLES) UsersBucket.UsersBucket());
                                            case (#groupsBucket) Principal.fromActor(await (with cycles = NEW_BUCKET_NB_CYCLES) GroupsBucket.GroupsBucket());
                                        };
                                    };
                                };
            
            switch ( memoryCanisters.get(CanistersKinds.compareCanistersKinds, #dynamic(canisterType)) ) {
                case (?map) map.add(newPrincipal, ());
                case (null) memoryCanisters.add(CanistersKinds.compareCanistersKinds, #dynamic(canisterType), Map.singleton(newPrincipal, ()));
            };

            allowedCanisters.add(newPrincipal, ());

            #ok(newPrincipal)
        } catch (e) {
            #err("Cannot create canister, error: " # Error.message(e))
        };
    };    

    // recharge numbers of cycles 
    func helperTopCanisters() : async () {
        for ( (nature, typeMap) in Map.entries(memoryCanisters) ) {
            let toppingAmount = switch (nature) {
                                    case (#static(staticKind)) {
                                        switch ( staticKind ) {
                                            case (#registries(registrykind)) {
                                                switch (registrykind) {
                                                    case (#indexesRegistry) TOPPING_AMOUNT_REGISTRY;
                                                };
                                            };
                                        };
                                    };
                                    case (#dynamic(dynamicKind)) {
                                        switch ( dynamicKind ) {
                                            case (#indexes(indexKind)) {
                                                switch (indexKind) {
                                                    case (#mainIndex) TOPPING_AMOUNT_INDEXES;
                                                };
                                            };
                                            case (#buckets(bucketKind)) {
                                                switch (bucketKind) {
                                                    case (#usersBucket) TOPPING_AMOUNT_BUCKETS;
                                                    case (#groupsBucket) TOPPING_AMOUNT_BUCKETS;
                                                };
                                            };
                                        };
                                    };
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

    func helperSendIndexToIndexesRegistry(indexPrincipal: Principal, indexKind: CanistersKinds.IndexesKind) : async () {
        try {
            await (actor(indexesRegistryPrincipal.toText()) : IndexesRegistry.IndexesRegistry).systemAddIndex(indexPrincipal, indexKind);
        } catch (e) {
            Debug.print("Cannot send index to IndexesRegistry, error: " # Error.message(e));
            apiErrorsRetryList.add(#errSendingIndexToIndexesRegistry({ indexPrincipal = indexPrincipal; indexKind = indexKind }));
        };
    };

    func helperHandleErrors() : async () {
        let batchToRetry = apiErrorsRetryList;
        apiErrorsRetryList := List.empty();

        for ( err in batchToRetry.values() ) {
            try {
                switch ( err ) {
                    case (#errSendingIndexToIndexesRegistry(errData)) await helperSendIndexToIndexesRegistry(errData.indexPrincipal, errData.indexKind);
                };
            } catch (e) {
                Debug.print("Error while handling errors: " # Error.message(e));
            };
        };
    };
};