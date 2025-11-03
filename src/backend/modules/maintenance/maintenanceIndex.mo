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
import Errors "../../shared/errors";
import Configs "../../shared/configs";
import UsersDataBucket "../usersData/usersDataBucket";
import TodosBucket "../todos/todosBucket";
import IC "mo:ic";

shared ({ caller = owner }) persistent actor class MaintenanceIndex() = this {
    type Index = {
        #usersDataIndex;
        #todosIndex;
        #groupsIndex;
    };

    type Bucket = {
        #usersDataBucket;
        #todosBucket;
        #groupsBucket;
    };

    var indexTodosPrincipal = Principal.anonymous();
    var indexUserDataPrincipal = Principal.anonymous();
    var indexGroupsPrincipal = Principal.anonymous();

    var bucketsTodosPrincipals = Map.empty<Principal, ()>();
    var bucketsUserDataPrincipals = Map.empty<Principal, ()>();
    var bucketsGroupsPrincipals = Map.empty<Principal, ()>();

    //
    // SYSTEM
    //

    // if ever one day the need arise, it's possible to massively optimise this func by using parralellized calls.
    // TODO:it might be necessary to distinguish the topping by canister
    system func timer(setGlobalTimer : (Nat64) -> ()) : async () {
        var principals = Array.flatten([
            [indexTodosPrincipal, indexUserDataPrincipal],
            Array.fromIter(Map.keys(bucketsTodosPrincipals)),
            Array.fromIter(Map.keys(bucketsUserDataPrincipals)),
            Array.fromIter(Map.keys(bucketsGroupsPrincipals))
        ]);

        for ( canisterPrincipal in Array.values(principals) ) {
            let status = await IC.ic.canister_status({ canister_id = canisterPrincipal });
            if (status.cycles > Configs.Consts.TOPPING_THRESHOLD) {
                Debug.print("Bucket low on cycles, requesting top-up for " # Principal.toText(canisterPrincipal) # "with " # Nat.toText(Configs.Consts.TOPPING_AMOUNT) # " cycles");

                try {
                    ignore (with cycles = Configs.Consts.TOPPING_AMOUNT) IC.ic.deposit_cycles({ canister_id = canisterPrincipal });
                } catch (e) {
                    Debug.print("Error while topping up bucket " # Principal.toText(canisterPrincipal) # ": " # Error.message(e));
                };
            };
        };

        // schedule next timer
        setGlobalTimer(Nat64.fromIntWrap(Time.now()) + Nat64.fromNat(Configs.Consts.TOPPING_TIMER_INTERVAL_NS));
    };

    //
    // API
    //

    public shared ({ caller }) func setIndexPrincipal(nature : Index, indexPrincipal : Principal) : async () {
        if (caller != owner) { Runtime.trap(Errors.ERR_CAN_ONLY_BE_CALLED_BY_OWNER) };

        switch (nature) {
            case (#usersDataIndex) indexUserDataPrincipal := indexPrincipal;
            case (#todosIndex) indexTodosPrincipal := indexPrincipal;
            case (#groupsIndex) indexGroupsPrincipal := indexPrincipal;
        };
    };

    public shared ({ caller }) func upgradeAllBuckets(nature : Bucket, code: Blob.Blob) : async Result.Result<(), Text> {
        if (caller != owner) { return #err(Errors.ERR_CAN_ONLY_BE_CALLED_BY_OWNER); };

        switch (nature) {
            case (#usersDataBucket) {
                for (principal in Map.keys(bucketsUserDataPrincipals)) {
                    try {
                        await IC.ic.install_code({ mode = #upgrade(null); canister_id = principal; wasm_module = code; arg = to_candid((Principal.anonymous())); sender_canister_version = null; });
                    } catch (e) {
                        Debug.print("Cannot upgrade UserData bucket " # Principal.toText(principal) # ": " # Error.message(e));
                    };
                }
            };
            case (#todosBucket) {
                for (principal in Map.keys(bucketsTodosPrincipals)) {
                    try {
                        await IC.ic.install_code({ mode = #upgrade(null); canister_id = principal; wasm_module = code; arg = to_candid((Principal.anonymous())); sender_canister_version = null; });
                    } catch (e) {
                        Debug.print("Cannot upgrade UserData bucket " # Principal.toText(principal) # ": " # Error.message(e));
                    };
                }
            };
            case (#groupsBucket) {
                for (principal in Map.keys(bucketsGroupsPrincipals)) {
                    try {
                        await IC.ic.install_code({ mode = #upgrade(null); canister_id = principal; wasm_module = code; arg = to_candid((Principal.anonymous())); sender_canister_version = null; });
                    } catch (e) {
                        Debug.print("Cannot upgrade UserData bucket " # Principal.toText(principal) # ": " # Error.message(e));
                    };
                }
            };
        };

        #ok()
    };

    public shared ({ caller }) func createBucket() : async Result.Result<Principal, Text> {
        let bucketprincipal =   if ( caller == indexUserDataPrincipal ) {
                                    try {
                                        let aktor = await (with cycles = Configs.Consts.NEW_BUCKET_NB_CYCLES) UsersDataBucket.UsersDataBucket(indexUserDataPrincipal);
                                        let principal = Principal.fromActor(aktor);

                                        Map.add(bucketsUserDataPrincipals, Principal.compare, Principal.fromActor(aktor), ());

                                        principal
                                    } catch (e) {
                                        return #err("Cannot create new bucket: " # Error.message(e));
                                    };
                                } else if ( caller == indexTodosPrincipal ) {
                                    try {
                                        let aktor       = await (with cycles = Configs.Consts.NEW_BUCKET_NB_CYCLES) TodosBucket.TodosBucket(indexTodosPrincipal);
                                        let principal   = Principal.fromActor(aktor);

                                        Map.add(bucketsTodosPrincipals, Principal.compare, Principal.fromActor(aktor), ());

                                        principal
                                    } catch (e) {
                                        return #err("Cannot create new bucket: " # Error.message(e));
                                    };
                                } else if ( caller == indexGroupsPrincipal ) {
                                    try {
                                        let aktor       = await (with cycles = Configs.Consts.NEW_BUCKET_NB_CYCLES) GroupsBucket.GroupsBucket(indexGroupsPrincipal);
                                        let principal   = Principal.fromActor(aktor);

                                        Map.add(bucketsGroupsPrincipals, Principal.compare, Principal.fromActor(aktor), ());

                                        principal
                                    } catch (e) {
                                        return #err("Cannot create new bucket: " # Error.message(e));
                                    }
                                }; 

        #ok(bucketprincipal)
    };
};