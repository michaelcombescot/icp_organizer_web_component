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
import MainIndex "../modules/indexes/mainIndex";
import GroupsBucket "../modules/todos/buckets/groupsBucket";
import UsersBucket "../modules/users/buckets/usersBucket";
import IndexesRegistry "indexesRegistry";
import Array "mo:core/Array";

// The coordinator is the main entry point to launch the application.
// Launching the coordinator will create all necessary buckets and indexes, it's the ONLY entry point, everything else is dynamically created.
// It will have several missions:
// - create buckets and indexes
// - top indexes and canisters with cycles
shared ({ caller = owner }) persistent actor class Coordinator() = this {
    let thisPrincipal = Principal.fromActor(this);

    /////////////
    // CONFIGS //
    /////////////

    let TIMER_INTERVAL_NS: Nat64    = 20_000_000_000;

    let NEW_BUCKET_NB_CYCLES        = 2_000_000_000_000;
    let NEW_INDEX_NB_CYCLES         = 2_000_000_000_000;

    ////////////
    // ERRORS //
    ////////////

    type errors = {
        #errSendingIndexToIndexesRegistry: { registryPrincipal: Principal; indexPrincipal: Principal; indexKind: CanistersKinds.IndexesKind };
        #errSendUsersMappingToMainIndex: { indexPrincipal: Principal };
    };

    let apiErrorsRetryList = List.empty<errors>();

    ////////////
    // MEMORY //
    ////////////

    let memory = {
        canisters = Map.empty<CanistersKinds.CanistersKind, Map.Map<Principal, ()>>();
        allowedCanisters = Map.empty<Principal, ()>();
        var usersMapping: [Principal] = [];
    };

    ////////////
    // SYSTEM //
    ////////////

    type inspectParams = {
        arg : Blob;
        caller : Principal;
        msg : {
        #handlerTopCanister : () -> (canisterPrincipal : Principal, nbCycles : Nat);
        #handlerUpgradeCanisterKind : () -> (nature : CanistersKinds.CanistersKind, wasmModule : Blob);
        #handlerCreateIndex : () -> (indexKind : CanistersKinds.IndexesKind);
        #handlerAddRegistry : () -> (registryPrincipal : Principal, registryKind : CanistersKinds.RegistriesKind);
        #handlerCreateBucket : () -> (bucketKind : CanistersKinds.BucketsKind);
        #handlerIsLegitCanister : () -> (canisterPrincipal : Principal);
      }
    };

    system func inspect(params: inspectParams) : Bool {
        switch ( params.msg ) {
            case (#handlerTopCanister(_))           memory.allowedCanisters.containsKey(params.caller);
            case (#handlerUpgradeCanisterKind(_))   params.caller == owner;
            case (#handlerAddRegistry(_))           params.caller == owner;
            case (#handlerCreateIndex(_))           params.caller == owner;
            case (#handlerCreateBucket(_))          memory.allowedCanisters.containsKey(params.caller);
            case (#handlerIsLegitCanister(_))       memory.allowedCanisters.containsKey(params.caller);
        }
    };
    
    system func timer(setGlobalTimer : (Nat64) -> ()) : async () {
        await helperHandleErrors();

        setGlobalTimer(Nat64.fromIntWrap(Time.now()) + TIMER_INTERVAL_NS);
    };

    /////////
    // API //
    /////////

    public shared func handlerTopCanister(canisterPrincipal: Principal, nbCycles: Nat) : async Result.Result<(), Text> {
        Debug.print("[coordinator] requesting top-up for " # canisterPrincipal.toText() # "with " # Nat.toText(nbCycles) # " cycles");

        try {
            await (with cycles = nbCycles) IC.ic.deposit_cycles({ canister_id = canisterPrincipal });
            #ok
        } catch (e) {
            let msg = "[coordinator] Error while topping bucket " # Principal.toText(canisterPrincipal) # ": " # Error.message(e);
            Debug.print(msg);
            #err(msg)
        }
    };

    public shared func handlerUpgradeCanisterKind(nature : CanistersKinds.CanistersKind, wasmModule: Blob.Blob) : async () {
        let ?canistersMap = memory.canisters.get(CanistersKinds.compareCanistersKinds, nature) else Runtime.trap("No canisters of type " # debug_show(nature) # " found");

        for ( canisterPrincipal in Map.keys(canistersMap) ) {
            try {
                await IC.ic.install_code({
                    mode = #upgrade(?{ 
                        wasm_memory_persistence = ?#keep; 
                        skip_pre_upgrade = null; 
                    });
                    canister_id = canisterPrincipal;
                    wasm_module = wasmModule;
                    arg = to_candid((thisPrincipal));
                    sender_canister_version = null;
            });                 
                Debug.print("[coordinator] Upgraded canister " # Principal.toText(canisterPrincipal));
            } catch (e) {
                Debug.print("[coordinator] Cannot upgrade bucket, error: " # Error.message(e));
            };
        };
    };

    public shared func handlerAddRegistry(registryPrincipal: Principal, registryKind: CanistersKinds.RegistriesKind) : async Result.Result<(), Text> {
        memory.allowedCanisters.add(registryPrincipal, ());
        switch ( memory.canisters.get(CanistersKinds.compareCanistersKinds, #static(#registries(registryKind))) ) {
            case (null) memory.canisters.add(CanistersKinds.compareCanistersKinds, #static(#registries(registryKind)), Map.singleton(registryPrincipal, ()));
            case (?map) map.add(registryPrincipal, ());
        };

        #ok
    };

    public shared func handlerCreateIndex(indexKind: CanistersKinds.IndexesKind) : async Result.Result<Principal, Text> {
        await helperCreateCanister(#indexes(indexKind))
    };

    public shared func handlerCreateBucket(bucketKind: CanistersKinds.BucketsKind) : async Result.Result<Principal, Text> {
        await helperCreateCanister(#buckets(bucketKind))
    };

    public query func handlerIsLegitCanister(canisterPrincipal: Principal) : async Bool {
        let ?_ = memory.allowedCanisters.get(canisterPrincipal) else return false;
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
                                                                case (#mainIndex) {
                                                                    let principal = Principal.fromActor(await (with cycles = NEW_INDEX_NB_CYCLES) MainIndex.MainIndex());
                                                                    await helperSendUsersMapping({ indexPrincipal = principal });
                                                                    principal
                                                                };
                                                            };
                                        
                                        // send to all indexes registry
                                        switch ( memory.canisters.get(CanistersKinds.compareCanistersKinds, #static(#registries(#indexesRegistry))) ) {
                                            case (null) ();
                                            case (?map) {
                                                for ( indexPrincipal in Map.keys(map) ) {
                                                    ignore helperSendNewIndexToIndexesRegistry({ registryPrincipal = indexPrincipal; indexPrincipal = newPrincipal; indexKind = indexKind });
                                                };
                                            };
                                        };

                                        newPrincipal
                                    };
                                    case (#buckets(bucketKind)) {
                                        switch (bucketKind) {
                                            case (#usersBucket) Principal.fromActor(await (with cycles = NEW_BUCKET_NB_CYCLES) UsersBucket.UsersBucket());
                                            case (#groupsBucket) Principal.fromActor(await (with cycles = NEW_BUCKET_NB_CYCLES) GroupsBucket.GroupsBucket());
                                        };
                                    };
                                };
            
            // add new canister to map of canisters
            switch ( memory.canisters.get(CanistersKinds.compareCanistersKinds, #dynamic(canisterType)) ) {
                case (?map) map.add(newPrincipal, ());
                case (null) memory.canisters.add(CanistersKinds.compareCanistersKinds, #dynamic(canisterType), Map.singleton(newPrincipal, ()));
            };

            // add new canister to allowed canisters
            memory.allowedCanisters.add(newPrincipal, ());

            #ok(newPrincipal)
        } catch (e) {
            #err("Cannot create canister, error: " # Error.message(e))
        };
    };

    func helperSendNewIndexToIndexesRegistry({ registryPrincipal: Principal; indexPrincipal: Principal; indexKind: CanistersKinds.IndexesKind}) : async () {
        try {
            await (actor(registryPrincipal.toText()) : IndexesRegistry.IndexesRegistry).systemAddIndex(indexPrincipal, indexKind);
        } catch (e) {
            Debug.print("[coordinator] Cannot send index to IndexesRegistry, error: " # Error.message(e));
            apiErrorsRetryList.add(#errSendingIndexToIndexesRegistry({ registryPrincipal = registryPrincipal; indexPrincipal = indexPrincipal; indexKind = indexKind }));
        };
    };

    func helperSendUsersMapping({ indexPrincipal: Principal }) : async () {
        try {
            // init user mapping if no already initialized
            if ( memory.usersMapping.size() == 0 ) {
                let newPrincipal = Principal.fromActor(await (with cycles = NEW_BUCKET_NB_CYCLES) UsersBucket.UsersBucket());
                memory.usersMapping := Array.tabulate<Principal>(10000, func(i) = newPrincipal);
            };

            await (actor(indexPrincipal.toText()) : MainIndex.MainIndex).systemSetUserMapping(memory.usersMapping);
            Debug.print("[coordinator] Sent users mapping to mainIndex " # Principal.toText(indexPrincipal));
        } catch (e) {
            Debug.print("[coordinator] Cannot send users mapping to MainIndex, error: " # Error.message(e));
            apiErrorsRetryList.add(#errSendUsersMappingToMainIndex({ indexPrincipal = indexPrincipal }));
        };
    };

    func helperHandleErrors() : async () {
        let errors = apiErrorsRetryList.values();
        apiErrorsRetryList.clear();

        for ( err in errors ) {
            switch (err) {
                case(#errSendingIndexToIndexesRegistry(params)) await helperSendNewIndexToIndexesRegistry(params);
                case(#errSendUsersMappingToMainIndex(params))   await helperSendUsersMapping(params);
            };
        };
    };
};