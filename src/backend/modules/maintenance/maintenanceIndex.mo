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
import Iter "mo:core/Iter";
import List "mo:core/List";
import Blob "mo:core/Blob";
import Interfaces "../../shared/interfaces";
import Errors "../../shared/errors";
import Configs "../../shared/configs";
import UsersDataBucket "../usersData/usersDataBucket";
import TodosBucket "../todos/todosBucket";
import TodosIndex "../todos/todosIndex";
import UsersDataIndex "../usersData/usersDataIndex";
import IC "mo:ic";

shared ({ caller = owner }) persistent actor class MaintenanceIndex() = this {
    let ERR_UNKNOWN_CANISTER_NATURE = "ERR_UNKNOWN_CANISTER_NATURE";

    type CanisterIndex = {
        #usersDataIndex;
        #todosIndex;
    };

    type CanisterBucket = {
        #usersDataBucket;
        #todosBucket;
    };

    type CanisterNature = {
        #index: CanisterIndex;
        #bucket: CanisterBucket;
    };

    var canisters = Map.empty<Principal, CanisterNature>();

    //
    // SYSTEM
    //

    // if ever one day the need arise, it's possible to massively optimise this func by using parralellized calls.
    // TODO:it might be necessary to distinguish the topping by canister
    system func timer(setGlobalTimer : (Nat64) -> ()) : async () {
        for ( canisterPrincipal in Map.keys(canisters) ) {
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

    public shared ({ caller }) func setIndexPrincipal(nature : CanisterIndex, indexPrincipal : Principal) : async () {
        if (caller != owner) { Runtime.trap(Errors.ERR_CAN_ONLY_BE_CALLED_BY_OWNER) };

        switch (nature) {
            case (#usersDataIndex) Map.add(canisters, Principal.compare, indexPrincipal, #index(#usersDataIndex));
            case (#todosIndex) Map.add(canisters, Principal.compare, indexPrincipal, #index(#todosIndex));
        };
    };

    public shared ({ caller }) func upgradeAllBuckets(nature : CanisterBucket, code: Blob.Blob) : async Result.Result<(), Text> {
        if (caller != owner) { return #err(Errors.ERR_CAN_ONLY_BE_CALLED_BY_OWNER); };

        let bucketsPrincipals = Iter.toArray(
                                    Iter.filterMap(
                                        Map.entries(canisters),
                                        func ((principal: Principal, canisterNature: CanisterNature)) : ?Principal {
                                            switch (canisterNature) {
                                                case (#bucket(bucketNature)) if (bucketNature == nature) { ?principal } else { null };
                                                case _ null;
                                            }
                                        }
                                    )
                                );

        for (principal in Array.values(bucketsPrincipals)) {
            try {
                await IC.ic.install_code({ mode = #upgrade(null); canister_id = principal; wasm_module = Blob.fromArray([8]); arg = Blob.fromArray([Principal.anonymous()]); sender_canister_version = null; });
            } catch (e) {
                Debug.print("Cannot upgrade UserData bucket " # Principal.toText(principal) # ": " # Error.message(e));
            };
        };

        #ok()
    };

    public shared ({ caller }) func createBucket() : async Result.Result<Principal, Text> {
        var newBucketPrincipal = Principal.anonymous();

        try {
            let newBucket = switch ( caller ) {
                case () {
                    await (with cycles = Configs.Consts.NEW_BUCKET_NB_CYCLES) aktor();
                };
                case (#todos(aktor)) {
                    await (with cycles = Configs.Consts.NEW_BUCKET_NB_CYCLES) aktor();
                };                
            };

            newBucketPrincipal := Principal.fromActor(newBucket);
        } catch (e) {
            return #err("Cannot create new bucket: " # Error.message(e));
        };
        
        Map.add(buckets, Principal.compare, newBucketPrincipal, { nature = nature });

        #ok(newBucketPrincipal)        
    };
};