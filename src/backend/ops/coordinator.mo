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
import Iter "mo:core/Iter";
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
        #errorUpdateToRegistry:     { indexKind: CanistersKinds.IndexKind; indexPrincipal: Principal };
        #errorSendBucketToIndex:    { indexPrincipal: Principal; indexKind: CanistersKinds.IndexKind; bucketPrincipal: Principal; bucketKind: CanistersKinds.BucketKind; };
        #errorSendIndexToBucket:    { bucketPrincipal: Principal; bucketKind: CanistersKinds.BucketKind; indexPrincipal: Principal };
    };

    var listAPIErrors = List.empty<APIErrors>();

    ////////////
    // STATES //
    ////////////

    let registryActor = actor (Principal.toText(registryInitPrincipal)) : Registry.Registry;

    let memoryCanisters     = Map.singleton<CanistersKinds.CanisterKind , Map.Map<Principal, ()>>( (#registry, Map.singleton<Principal, ()>( (registryInitPrincipal, () ) )) );
    let memoryFreeBuckets   = Map.empty<CanistersKinds.BucketKind, List.List<Principal>>();

    ////////////
    // SYSTEM //
    ////////////

    type inspectParams = {
        arg : Blob;
        caller : Principal;
        msg : {
            #handlerUpgradeCanister : () -> {code : Blob; nature : CanistersKinds.CanisterKind};
            #handlerAddIndex : () -> { indexKind: CanistersKinds.IndexKind };
            #handlerGiveFreeBucket : () -> {bucketKind : CanistersKinds.BucketKind};
        }
    };

    system func inspect(params: inspectParams) : Bool {
        switch ( params.msg ) {
            case (#handlerAddIndex(_))          params.caller != owner;
            case (#handlerUpgradeCanister(_))   params.caller != owner;
            case (#handlerGiveFreeBucket(_))    true ; // TODO: check with known indexes principals
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

        // api errors retry
        let tempList = List.empty<APIErrors>();
        for ( error in List.values(listAPIErrors) ) {
            switch (error) {
                case (#errorUpdateToRegistry(params)) {
                    switch (await helperUpdateRegistry(params)) {
                        case (#ok) ();
                        case (#err(_)) List.add(tempList, error); 
                    };
                };
                case (#errorSendBucketToIndex(params)) {
                    switch ( await helperSendBucketToIndexes(params) ) {
                        case (#ok) ();
                        case (#err(_)) List.add(tempList, error);
                    };
                };
                case (#errorSendIndexToBucket(params)) {
                    switch ( await helperSendIndexToBucket(params) ) {
                        case (#ok) ();
                        case (#err(_)) List.add(tempList, error);
                    }
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
    public shared func handlerUpgradeCanister({ nature : CanistersKinds.CanisterKind; code: Blob.Blob }) : async () {
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

    //
    // API FOR INDEXES
    //

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
        switch (canisterType) {
            case (#registry) (); // registry is never created by the helper
            case(#indexes(indexKind)) {
                // for indexes:
                // - create a new index
                // - add it to the list of indexes
                // - add it to the main store

                let aktor = switch (indexKind) {
                                case (#todosIndex) await (with cycles = NEW_INDEX_NB_CYCLES) TodosIndex.TodosIndex();
                            };

                let newPrincipal = Principal.fromActor(aktor);  

                // update main store
                switch ( Map.get(memoryCanisters, CanistersKinds.compareCanisterKinds, #indexes(indexKind)) ) {
                    case null Map.add(memoryCanisters, CanistersKinds.compareCanisterKinds, #indexes(indexKind), Map.singleton<Principal, ()>(newPrincipal, ()));
                    case (?map) Map.add(map, Principal.compare, newPrincipal, ());
                };

                // update registry
                switch ( await helperUpdateRegistry({ indexKind = indexKind; indexPrincipal = newPrincipal; }) ) {
                    case (#ok) ();
                    case (#err(_)) List.add(listAPIErrors, #errorUpdateToRegistry({ indexKind = indexKind; indexPrincipal = newPrincipal; }));
                };

                // send new index to all buckets
                switch ( indexKind ) {
                    case (#todosIndex) {
                        for (bucketData in helperFindBucketsForIndex(indexKind).values()) {
                            let params = { bucketPrincipal = bucketData.bucketPrincipal; bucketKind = bucketData.bucketKind; indexPrincipal = newPrincipal };

                            switch ( await helperSendIndexToBucket(params) ) {
                                case (#ok) ();
                                case (#err(_)) List.add(listAPIErrors, #errorSendIndexToBucket(params));
                            };
                        };
                    };
                };
            };
            case(#buckets(bucketType)) {
                // for buckets:
                // - create a new bucket
                // - check if a new bucket is needed (the number of free buckets per type must at least be equal to the number of associated indexes)
                // - add it to the list of free buckets
                // - add it to the main store
                let indexKind = switch ( bucketType ) {
                                    case (#todos(todoBucketType)) {
                                        switch (todoBucketType) {
                                            case (#todosUsersDataBucket) #indexes(#todosIndex);
                                            case (#todosGroupsBucket)    #indexes(#todosIndex);
                                        };
                                    };
                                };


                let nbIndexes = switch ( Map.get(memoryCanisters, CanistersKinds.compareCanisterKinds, indexKind) ) {
                                    case null 0;
                                    case (?map) Map.size(map);
                                };
                    
                let nbFreeBuckets = switch ( Map.get(memoryFreeBuckets, CanistersKinds.compareBucketsKinds, bucketType) ) {
                                        case null 0;
                                        case (?list) List.size(list);
                                    };

                if ( nbFreeBuckets >= nbIndexes + 1 ) { return; };

                let aktor = switch (bucketType) {
                                case (#todos(todoBucketType)) {
                                    switch (todoBucketType) {
                                        case (#todosUsersDataBucket) await (with cycles = NEW_BUCKET_NB_CYCLES) TodosUsersDataBucket.TodosUsersDataBucket();
                                        case (#todosGroupsBucket)    await (with cycles = NEW_BUCKET_NB_CYCLES) TodosGroupsBucket.TodosGroupsBucket();
                                    };
                                };
                            };

                let newPrincipal = Principal.fromActor(aktor);

                // update free buckets store
                switch ( Map.get(memoryFreeBuckets, CanistersKinds.compareBucketsKinds, bucketType) ) {
                    case (?list) List.add(list, newPrincipal);
                    case null Map.add(memoryFreeBuckets, CanistersKinds.compareBucketsKinds, bucketType, List.singleton<Principal>(newPrincipal));
                };

                // update main store
                switch ( Map.get(memoryCanisters, CanistersKinds.compareCanisterKinds, #buckets(bucketType)) ) {
                    case null Map.add(memoryCanisters, CanistersKinds.compareCanisterKinds, #buckets(bucketType), Map.singleton<Principal, ()>(newPrincipal, ()));
                    case (?map) Map.add(map, Principal.compare, newPrincipal, ());
                };

                // send new bucket to all indexes
                switch ( bucketType ) {
                    case (#todos(_)) {
                        for (indexPrincipal in helperFindIndexesPrincipals(#todosIndex).values()) {
                            let params = { indexPrincipal = indexPrincipal; indexKind = #todosIndex; bucketPrincipal = newPrincipal; bucketKind = bucketType; };

                            switch ( await helperSendBucketToIndexes(params) ) {
                                case (#ok) ();
                                case (#err(_)) List.add(listAPIErrors, #errorSendBucketToIndex(params));
                            }; 
                        };
                    };
                };
            };
        };
    };

    func helperUpdateRegistry({ indexKind: CanistersKinds.IndexKind; indexPrincipal: Principal }) : async Result.Result<(), Text> {
        try {
            #ok( await registryActor.addIndex({ kind = indexKind; principal = indexPrincipal }) );
        } catch (e) {
            #err( "Error while sending indexes to registry: " # Error.message(e) )
        }  
    };

    func helperSendBucketToIndexes({ indexPrincipal: Principal; indexKind: CanistersKinds.IndexKind; bucketPrincipal: Principal; bucketKind: CanistersKinds.BucketKind }) : async Result.Result<(), Text> {
        let bucketType =    switch (bucketKind) {
                                case (#todos(bucketType)) bucketType;
                            };

        try {
            switch (indexKind) {
                case (#todosIndex) {
                    let aktor = actor(Principal.toText(indexPrincipal)) : TodosIndex.TodosIndex;
                    #ok( await aktor.systemAddBucket({ bucketKind = bucketType; bucketPrincipal = bucketPrincipal }));
                };
            };
        } catch (e) {
            #err( "Error while sending buckets to index: " # Error.message(e) )
        }
    };

    func helperSendIndexToBucket({ bucketPrincipal: Principal; bucketKind: CanistersKinds.BucketKind; indexPrincipal: Principal }) : async Result.Result<(), Text> {
        try {
            switch (bucketKind) {
                case (#todos(bucketType)) {
                    switch (bucketType) {
                        case (#todosUsersDataBucket) {
                            let bucketActor = actor(Principal.toText(bucketPrincipal)) : TodosUsersDataBucket.TodosUsersDataBucket;
                            #ok( await bucketActor.systemAddIndex({ indexPrincipal = indexPrincipal }) );
                        };
                        case (#todosGroupsBucket) {
                            let bucketActor = actor(Principal.toText(bucketPrincipal)) : TodosGroupsBucket.TodosGroupsBucket;
                            #ok( await bucketActor.systemAddIndex({ indexPrincipal = indexPrincipal }) );
                        };
                    }
                };
            }
        } catch (e) {
            #err( "Error while sending indexes to bucket: " # Error.message(e) )
        }
    };

    func helperFindIndexesPrincipals(indexKind: CanistersKinds.IndexKind) : [Principal] {
        switch ( Map.get(memoryCanisters, CanistersKinds.compareCanisterKinds, #indexes(indexKind)) ) {
            case null [];
            case (?map) Iter.toArray(Map.keys(map));
        }
    };

    func helperFindBucketsForIndex(indexKind: CanistersKinds.IndexKind) : [{bucketKind: CanistersKinds.BucketKind; bucketPrincipal: Principal}] {
        let list = List.empty<{bucketKind: CanistersKinds.BucketKind; bucketPrincipal: Principal}>();

        switch ( indexKind ) {
            case (#todosIndex) {
                for (bucketKind in CanistersKinds.bucketTodoKindArray.values()) {
                    switch ( Map.get(memoryCanisters, CanistersKinds.compareCanisterKinds, #buckets(#todos(bucketKind))) ) {
                        case null ();
                        case (?map) {
                            for (principal in Map.keys(map)) {
                                List.add( list, {bucketKind = #todos(bucketKind); bucketPrincipal = principal} );  
                            };
                        };
                    };
                };
            };
        };

        List.toArray(list)
    };
};