import Debug "mo:core/Debug";
import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Map "mo:core/Map";
import Nat64 "mo:core/Nat64";
import Time "mo:core/Time";
import Nat "mo:core/Nat";
import Error "mo:core/Error";
import Interfaces "../../shared/interfaces";
import Errors "../../shared/errors";
import Configs "../../shared/configs";
import UsersDataBucket "../usersData/usersDataBucket";
import TodosBucket "../todos/todosBucket";
import MaintenanceModel "./maintenanceModel"

shared ({ caller = owner }) persistent actor class MaintenanceIndex() = this {
    type BucketData = {
        nature: MaintenanceModel.Nature;
    };

    var buckets = Map.empty<Principal, BucketData>();

    transient let allowedCallers = MaintenanceModel.makeAllowedCallers();

    //
    // SYSTEM
    //

    // if ever one day the need arise, it's possible to massively optimise this func by using parralellized calls
    system func timer(setGlobalTimer : (Nat64) -> ()) : async () {
        for ((bucketPrincipal, _) in Map.entries(buckets)) {
            let status = await Interfaces.ManagementCanister.canister.canister_status({ canister_id = bucketPrincipal });
            if (status.cycles > Configs.Consts.TOPPING_THRESHOLD) {
                Debug.print("Bucket low on cycles, requesting top-up for " # Principal.toText(bucketPrincipal) # "with " # Nat.toText(Configs.Consts.TOPPING_AMOUNT) # " cycles");

                try {
                    ignore (with cycles = Configs.Consts.TOPPING_AMOUNT) Interfaces.ManagementCanister.canister.deposit_cycles({ canister_id = bucketPrincipal });
                } catch (e) {
                    Debug.print("Error while topping up bucket " # Principal.toText(bucketPrincipal) # ": " # Error.message(e));
                };
            };
        };

        // schedule next timer
        setGlobalTimer(Nat64.fromIntWrap(Time.now()) + Nat64.fromNat(Configs.Consts.TOPPING_TIMER_INTERVAL_NS));
    };

    public shared ({ caller }) func upgradeAllBuckets(nature : MaintenanceModel.Nature) : async Result.Result<(), Text> {
        if (caller != owner) { return #err(Errors.ERR_CAN_ONLY_BE_CALLED_BY_OWNER); };

        let bucketsOfNature = Map.filter(buckets, Principal.compare, func(_, bucketData) = bucketData.nature == nature );

        switch (nature) {
            case (#usersData) {
                for ((bucketPrincipal, _) in Map.entries(bucketsOfNature)) {
                    let userDataBucket = actor (Principal.toText(bucketPrincipal)) : UsersDataBucket.UsersDataBucket;

                    try {
                        ignore await (system UsersDataBucket.UsersDataBucket)(#upgrade userDataBucket)();
                    } catch (e) {
                        Debug.print("Cannot upgrade UserData bucket " # Principal.toText(bucketPrincipal) # ": " # Error.message(e));
                    };
                };
            };
            case (#todos) {
                for ((bucketPrincipal, _) in Map.entries(bucketsOfNature)) {
                    let todoBucket = actor (Principal.toText(bucketPrincipal)) : TodosBucket.TodosBucket;

                    try {
                        ignore await (system UsersDataBucket.UsersDataBucket)(#upgrade todoBucket)();
                    } catch (e) {
                        Debug.print("Cannot upgrade UserData bucket " # Principal.toText(bucketPrincipal) # ": " # Error.message(e));
                    };
                };
            };
        };

        #ok()
    };

    //
    // API
    //

    public shared ({ caller }) func createBucket() : async Result.Result<Principal, Text> {
        let ?(nature, actorKind) = Map.get(allowedCallers, Principal.compare, caller) else return #err(Errors.ERR_CAN_ONLY_BE_CALLED_BY_INDEX);

        var newBucketPrincipal = Principal.anonymous();
        try {
            let newBucket = switch actorKind {
                case (#usersData(aktor)) {
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