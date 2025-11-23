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

    /////////////
    // CONFIGS //
    /////////////

    let TOPPING_TIMER_INTERVAL_NS   = 20_000_000_000;
    let TOPPING_THRESHOLD           = 1_000_000_000_000;
    let TOPPING_AMOUNT_BUCKETS      = 1_000_000_000_000;
    let TOPPING_AMOUNT_INDEXES      = 1_000_000_000_000;

    let NEW_BUCKET_NB_CYCLES        = 2_000_000_000_000;

    // must be at least equal to the number of indexes, the goal is to be able to pick a bucket already registered in the global canister store, it ensures that indexes will know about it beforehand.
    // Otherwise, an index A could create an item on the new bucket, while index B is not aware of it yet.
    let NB_FREE_BUCKETS             = 2;

    ////////////
    // STATES //
    ////////////

    let memoryCanisters     = Map.empty<CanistersKinds.CanisterKind , Map.Map<Principal, ()>>();
    let memoryFreeBuckets   = Map.empty<CanistersKinds.BucketKind , List.List<Principal>>();

    ////////////
    // SYSTEM //
    ////////////

    // the timer has 2 main function: 
    // - topping buckets/indexes with cycles
    // - create new free buckets if needed
    system func timer(setGlobalTimer : (Nat64) -> ()) : async () {
        // top canisters
        for ( (nature, typeMap) in Map.entries(memoryCanisters) ) {
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
                let status = await IC.ic.canister_status({ canister_id = canisterPrincipal });
                if (status.cycles > TOPPING_THRESHOLD) {
                    Debug.print("Bucket low on cycles, requesting top-up for " # Principal.toText(canisterPrincipal) # "with " # Nat.toText(toppingAmount) # " cycles");

                    try {
                        ignore (with cycles = toppingAmount) IC.ic.deposit_cycles({ canister_id = canisterPrincipal });
                    } catch (e) {
                        Debug.print("Error while topping up bucket " # Principal.toText(canisterPrincipal) # ": " # Error.message(e));
                    };
                };
            };


        };

        // create free canisters
        for ( nature in CanistersKinds.bucketKindArray.values() ) {
            await createFreeBucket(nature);
        };

        // set timer
        setGlobalTimer(Nat64.fromIntWrap(Time.now()) + Nat64.fromNat(TOPPING_TIMER_INTERVAL_NS));
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
        if (caller != owner) { Runtime.trap(ERR_CAN_ONLY_BE_CALLED_BY_OWNER); };

        let ?canistersMap = Map.get(memoryCanisters, CanistersKinds.compareCanisterKinds, nature) else Runtime.trap("No canisters of type " # debug_show(nature) # " found");

        for ( canisterPrincipal in Map.keys(canistersMap) ) {
            try {
                ignore IC.ic.install_code({ mode = #upgrade(null); canister_id = canisterPrincipal; wasm_module = code; arg = to_candid((Principal.anonymous())); sender_canister_version = null; });                   
            } catch (e) {
                Debug.print("Cannot upgrade bucket, error: " # Error.message(e));
            };
        };
    };

    // add a new index to the index list, index are created by hand in the dfx file.
    public shared ({ caller }) func handlerAddIndex({nature: CanistersKinds.IndexKind; principal: Principal}) : async () {
        if (caller != owner) { Runtime.trap( ERR_CAN_ONLY_BE_CALLED_BY_OWNER ); };

        switch ( Map.get(memoryCanisters, CanistersKinds.compareCanisterKinds, #indexes(nature)) ) {
            case null Map.add(memoryCanisters, CanistersKinds.compareCanisterKinds, #indexes(nature), Map.singleton<Principal, ()>(principal, ()));
            case (?mapType) Map.add(mapType, Principal.compare, principal, ());
        };
    };

    // remove an index if necessary
    public shared ({ caller }) func handlerRemoveIndex({nature: CanistersKinds.IndexKind; principal: Principal}) : async Result.Result<(), Text> {
        if (caller != owner) { return #err(ERR_CAN_ONLY_BE_CALLED_BY_OWNER); };

        switch ( Map.get(memoryCanisters, CanistersKinds.compareCanisterKinds, #indexes(nature)) ) {
            case null ();
            case (?mapType) Map.remove(mapType, Principal.compare, principal);
        };

        #ok
    };

    //
    // INTERCANISTERS CALLS
    //

    // retrieve Principal of all indexes of a specific type
    public query ({ caller }) func handlerGetIndexes({nature: CanistersKinds.IndexKind}) : async [Principal] {
        if ( List.contains(helperGetBucketsPrincipals(), Principal.equal, caller) ) { Runtime.trap( ERR_CAN_ONLY_BE_CALLED_BY_BUCKETS # " but called by " # debug_show(caller) ); };

        let ?indexesMap = Map.get(memoryCanisters, CanistersKinds.compareCanisterKinds, #indexes(nature)) else Runtime.trap( "No indexes of type " # debug_show(nature) # " found");
        Array.fromIter( Map.keys(indexesMap) )
    };

    // retrieve Principal of all buckets of a specific type
    public shared ({ caller }) func handlerGetBuckets({nature: CanistersKinds.BucketKind}) : async [Principal] {
        if ( List.contains(helperGetIndexesPrincipals(), Principal.equal, caller) ) { Runtime.trap( ERR_CAN_ONLY_BE_CALLED_BY_INDEX # " but called by " # debug_show(caller) ); };

        let ?bucketsMap = Map.get(memoryCanisters, CanistersKinds.compareCanisterKinds, #buckets(nature)) else Runtime.trap( "No buckets of type " # debug_show(nature) # " found");

        Array.fromIter( Map.keys(bucketsMap) )
    };

    // retrieve a free bucket principal from the free bucket store
    public shared ({ caller }) func handlerGetFreeBucket({nature: CanistersKinds.BucketKind}) : async Principal {
        if ( List.contains(helperGetBucketsPrincipals(), Principal.equal, caller) ) { Runtime.trap( ERR_CAN_ONLY_BE_CALLED_BY_BUCKETS # " but called by " # debug_show(caller) ); };

        let ?list = Map.get(memoryFreeBuckets, CanistersKinds.compareBucketsKinds, nature) else Runtime.trap( "No free buckets of type " # debug_show(nature) # " found");

        switch ( List.removeLast(list) ) {
            case null Runtime.trap( "List of free bucket is empty for nature " # debug_show(nature) );
            case (?principal) principal;
        }
    };

    /////////////
    // HELPERS //
    /////////////

    // add a new free bucket of the specific type to the list of free buckets
    func createFreeBucket(bucketType : CanistersKinds.BucketKind) : async () {
        let freeBuckets = Map.get(memoryFreeBuckets, CanistersKinds.compareBucketsKinds, bucketType);

        let nbFreeBuckets = switch ( freeBuckets ) {
                                case null 0;
                                case (?list) List.size(list);
                            };

        if ( nbFreeBuckets >= NB_FREE_BUCKETS ) { return; };

        // generate a new bucket and retrieve the principal
        let aktor = await switch (bucketType) {
                            case(#todos(todosBucketType)) {
                                switch (todosBucketType) {
                                    case (#todosTodosBucket)        (with cycles = NEW_BUCKET_NB_CYCLES) TodosTodosBucket.TodosTodosBucket();
                                    case (#todosUsersDataBucket)    (with cycles = NEW_BUCKET_NB_CYCLES) TodosUsersDataBucket.TodosUsersDataBucket();
                                    case (#todosListsBucket )       (with cycles = NEW_BUCKET_NB_CYCLES) TodosListsBucket.TodosListsBucket();
                                    case (#todosGroupsBucket)       (with cycles = NEW_BUCKET_NB_CYCLES) TodosGroupsBucket.TodosGroupsBucket();
                                }
                            };
                        };

        let newPrincipal = Principal.fromActor(aktor);

        // update free buckets store
        switch ( freeBuckets ) {
            case (?list) List.add(list, newPrincipal);
            case null Map.add(memoryFreeBuckets, CanistersKinds.compareBucketsKinds, bucketType, List.singleton<Principal>(newPrincipal));
        };

        // update main store with the new bucket
        switch ( Map.get(memoryCanisters, CanistersKinds.compareCanisterKinds, #buckets(bucketType)) ) {
            case null Map.add(memoryCanisters, CanistersKinds.compareCanisterKinds, #buckets(bucketType), Map.singleton<Principal, ()>(newPrincipal, ()));
            case (?map) Map.add(map, Principal.compare, newPrincipal, ());
        };
    };

    func helperGetBucketsPrincipals() : List.List<Principal> {
        let buckets = List.empty<Principal>();

        for ( nature in CanistersKinds.bucketKindArray.values() ) {
            switch (nature) {
                case (#todos(todoType)) {
                    switch (todoType) {
                        case (#todosTodosBucket or #todosUsersDataBucket or #todosListsBucket or #todosGroupsBucket) {
                            switch ( Map.get(memoryCanisters, CanistersKinds.compareCanisterKinds, #buckets(nature)) ) {
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
                    switch ( Map.get(memoryCanisters, CanistersKinds.compareCanisterKinds, #indexes(nature)) ) {
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
};