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
import Array "mo:core/Array";
import Runtime "mo:core/Runtime";
import CanistersKinds "canistersKinds";
import TodosUsersDataBucket "../todos/buckets/todosUsersDataBucket";
import TodosGroupsBucket "../todos/buckets/todosGroupsBucket";
import TodosIndex "../todos/todosIndex";
import Registry "registry";

// The coordinator is the main entry point to launch the application.
// Launching the coordinator will create all necessary buckets and indexes, it's the ONLY entry point, everything else is dynamically created.
// It will have several missions:
// - create buckets and indexes
// - top indexes and canisters with cycles
// - check if there are free buckets in the bucket pool.The bucket pool is here for the different indexes to pick new active buckets when a buckets return a signal it's full.
shared ({ caller = owner }) persistent actor class Coordinator({ registryInitPrincipal: Principal}) = this {
    ////////////
    // ERRORS //
    ////////////

    let ERR_CAN_ONLY_BE_CALLED_BY_OWNER     = "ERR_CAN_ONLY_BE_CALLED_BY_OWNER";
    let ERR_CAN_ONLY_BE_CALLED_BY_BUCKETS   = "ERR_CAN_ONLY_BE_CALLED_BY_BUCKETS";
    let ERR_CAN_ONLY_BE_CALLED_BY_INDEX     = "ERR_CAN_ONLY_BE_CALLED_BY_INDEX";

    type APIErrors = {
        #errorSendIndexToRegistry: { kind: CanistersKinds.IndexKind; principal: Principal };
        #errorSendBucketToIndex: { indexPrincipal: Principal; indexKind: CanistersKinds.IndexKind; bucketPrincipal: Principal; bucketKind: CanistersKinds.BucketKind; };
        #errorSendIndexToBucket: { bucketPrincipal: Principal; bucketKind: CanistersKinds.BucketKind; indexPrincipal: Principal; indexKind: CanistersKinds.IndexKind; };
    };

    var listAPIErrors = List.empty<APIErrors>();

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
    // STATES //
    ////////////

    let registryActor = actor (Principal.toText(registryInitPrincipal)) : Registry.Registry;

    let memoryCanisters = Map.singleton<CanistersKinds.CanisterKind , Map.Map<Principal, ()>>( (#registry, Map.singleton<Principal, ()>( (registryInitPrincipal, () ) )) );

    ////////////
    // SYSTEM //
    ////////////

    type Msg = {
        #handlerAddIndex : () -> {nature : CanistersKinds.IndexKind; principal : Principal};
        #handlerUpgradeCanister : () -> {code : Blob; nature : CanistersKinds.CanisterKind};

        #handlerGiveFreeBucket : () -> Principal;
    };

    system func inspect({ arg : Blob; caller : Principal; msg : Msg }) : Bool {
        switch msg {
            case (#handlerAddIndex(_)) caller != owner;
            case (#handlerUpgradeCanister(_)) caller != owner;
            case (#handlerGiveFreeBucket(_)) true;
        }
    };

    // the timer has 2 main function 
    // => topping buckets/indexes with cycles, the amount of cycles will depend on the canister type (index or bucket)
    // => handle errors and retry async calls id needed
    system func timer(setGlobalTimer : (Nat64) -> ()) : async () {
        // topping logic
        for ( (nature, typeMap) in Map.entries(memoryCanisters) ) {
            let toppingAmount = switch (nature) {
                                    case (#indexes(_)) TOPPING_AMOUNT_INDEXES;                        
                                    case (#buckets(_)) TOPPING_AMOUNT_BUCKETS;                
                                    case (#registry(_)) TOPPING_AMOUNT_REGISTRY;
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

        // error handling
        let tempList = List.empty<APIErrors>();
        for ( error in List.values(listAPIErrors) ) {
            switch (error) {
                case (#errorSendIndexToRegistry(params)) {
                    try {
                        ignore registryActor.addIndex(params);
                    } catch (e) {
                        Debug.print("Error while sending index to registry: " # Error.message(e));
                        List.add(tempList, error);
                    }
                };
                case (#errorSendBucketToIndex(params)) {
                    switch ( params.indexKind ) {
                        case (#todosIndex) {
                            try {
                                ignore (actor(Principal.toText(params.indexPrincipal)) : TodosIndex.TodosIndex).addBucket({ bucketPrincipal = params.bucketPrincipal; bucketKind = params.bucketKind; }));
                            } catch (e) {
                                Debug.print("Error while sending bucket to index: " # Error.message(e));
                                List.add(tempList, error);
                            }
                        };
                    };
                };
                case (#errorSendIndexToBucket(params)) {
                    // TODO
                };
            };
        };

        listAPIErrors := tempList;

        // reset timer
        setGlobalTimer(Nat64.fromIntWrap(Time.now()) + Nat64.fromNat(TIMER_INTERVAL_NS));
    };

    /////////
    // API //
    /////////

    //
    // ADMIN 
    //

    // upgrade a canister of a specific type, is to be used in cli with the command (replace for the right canister path):
    // - dfx canister call organizerMaintenance upgradeAllBuckets '(#buckettype, blob "'$(hexdump -ve '1/1 "\\\\%02x"' .dfx/local/canisters/organizerUsersDataBucket/organizerUsersDataBucket.wasm)'")'
    public shared ({ caller }) func handlerUpgradeCanister({ nature : CanistersKinds.CanisterKind; code: Blob.Blob }) : async () {
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
    public shared ({ caller }) func handlerAddIndex({nature: CanistersKinds.IndexKind; principal: Principal}) : async () {
        try {
            ignore helperCreateCanister({ canisterType = #indexes(nature) });
        } catch (e) {
            Debug.print("Cannot create index, error: " # Error.message(e));
        }
    };

    //
    // INDEXES
    //

    public shared func handlerGiveFreeBucket({ bucketKind: CanistersKinds.BucketKind }) : async Principal {
        switch( Map.get(memoryFreeBuckets) )
    };

    /////////////
    // HELPERS //
    /////////////

    // send a subtype of canisters to other canisters
    // main usage:
    // - send indexes to the registry
    // - send a set of buckets to indexes
    // - send a set of indexes to buckets
    func sendCanistersPrincipals(canistersType: CanistersKinds.CanisterKind) : async () {
        switch ( canistersType ) {
            case (#indexes(indexType)) {
                
            };
            case (#buckets(bucketType)) {

            };
            case (#registry(registryType)) {
                
            };
        };
    };

    func helperCreateCanister({ canisterType : CanistersKinds.CanisterKind }) : async () {
        switch (canisterType) {
            case (#registry) (); // registry is never created by the helper
            case(#indexes(indexType)) {
                // for indexes:
                // - create a new index
                // - add it to the list of indexes
                // - add it to the main store

                let aktor = switch (indexType) {
                                case (#todosIndex) await (with cycles = NEW_INDEX_NB_CYCLES) TodosIndex.TodosIndex();
                            };

                let newPrincipal = Principal.fromActor(aktor);  

                // update main store
                switch ( Map.get(memoryCanisters, CanistersKinds.compareCanisterKinds, #indexes(indexType)) ) {
                    case null Map.add(memoryCanisters, CanistersKinds.compareCanisterKinds, #indexes(indexType), Map.singleton<Principal, ()>(newPrincipal, ()));
                    case (?map) Map.add(map, Principal.compare, newPrincipal, ());
                };

                // update registry
                let principals = 

                try {
                    ignore registryActor.addIndex({ kind = indexType; principal = newPrincipal });
                } catch (e) {
                    Debug.print("Error while sending indexes to registry: " # Error.message(e));
                    List.add(listAPIErrors, #errorSendIndexesToRegistry);
                };
            };
            case(#buckets(bucketType)) {
                // for buckets:
                // - create a new bucket
                // - check if a new bucket is needed (the number of free buckets per type must at least be equal to the number of associated indexes)
                // - add it to the list of free buckets
                // - add it to the main store
                let nbFreeBuckets = switch ( Map.get(memoryFreeBuckets, CanistersKinds.compareBucketsKinds, bucketType) ) {
                                        case null 0;
                                        case (?list) List.size(list);
                                    };

                if ( nbFreeBuckets >= List.size(listIndexesPrincipals) + 1 ) { return; };

                let aktor = switch (bucketType) {
                                case (#todo(todoBucketType)) {
                                    switch (todoBucketType) {
                                        case (#usersDataBucket) (with cycles = NEW_BUCKET_NB_CYCLES) UsersDataBucket.UsersDataBucket();
                                        case (#groupsBucket)    (with cycles = NEW_BUCKET_NB_CYCLES) GroupsBucket.GroupsBucket();
                                    };
                                };
                            };

                let newPrincipal = Principal.fromActor(aktor);

                // update free buckets store
                switch ( freeBuckets ) {
                    case (?list) List.add(list, newPrincipal);
                    case null Map.add(memoryFreeBuckets, CanistersKinds.compareBucketsKinds, bucketType, List.singleton<Principal>(newPrincipal));
                };

                // update main store
                switch ( Map.get(memoryCanisters, CanistersKinds.compareCanisterKinds, #buckets(bucketType)) ) {
                    case null Map.add(memoryCanisters, CanistersKinds.compareCanisterKinds, #buckets(bucketType), Map.singleton<Principal, ()>(newPrincipal, ()));
                    case (?map) Map.add(map, Principal.compare, newPrincipal, ());
                };

                // update buckets list
                List.add(listBucketsPrincipals, newPrincipal);
            };
        };
    };
};