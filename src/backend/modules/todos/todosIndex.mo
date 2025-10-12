import Principal "mo:core/Principal";
import Debug "mo:core/Debug";
import Map "mo:core/Map";
import Result "mo:core/Result";
import Error "mo:core/Error";
import OrderedMap "mo:base/OrderedMap";
import Interfaces "../../shared/interfaces";
import Configs "../../shared/configs";
import Errors "../../shared/errors";
import Todo "todoModel";

type BucketData = {
    principal: Principal;
    nbEntries: Nat;
};

shared ({ caller = owner }) persistent actor class TodosIndex() = this {
    transient let bucketMapOperations = OrderedMap.Make<Principal>(Principal.compare);
    var bucketsStore = bucketMapOperations.empty<BucketData>();

    var todosOnBuckets = Map.empty<Principal, Principal>();

    //
    // API 
    //

    public shared ({ caller }) func createTodo(todo: Todo.Todo) : async Result.Result<Principal, Text> {
        if ( caller == Principal.anonymous() ) { return #err(Errors.ERR_NOT_CONNECTED); };

        #err("ousse")
    };

    //
    // PRIVATE
    //

    // create a new bucket if the last one is full
    func getOrCreateBucket() : async Result.Result<Principal, Text> {
        var mustCreateBucket = false;
        var respBucketPrincipal = Principal.anonymous();
        
        switch (bucketMapOperations.maxEntry(bucketsStore)) {
            case (?(bucketPrincipal, bucket)) {
                if (bucket.nbEntries <= Configs.Consts.BUCKET_TODOS_MAX_ENTRIES) {
                    respBucketPrincipal := bucketPrincipal;
                } else {
                    mustCreateBucket := true;
                };
            };
            case null {
                mustCreateBucket := true
            };
        };

        if (mustCreateBucket) {
            try {
                switch ( await Interfaces.MaintenanceIndex.canister.addBucket() ) {
                    case (#ok(bucketPrincipal)) {
                        respBucketPrincipal := bucketPrincipal;

                        bucketsStore := bucketMapOperations.put(bucketsStore, respBucketPrincipal, { principal = respBucketPrincipal; nbEntries = 1; });
                    };
                    case (#err(e)) {
                        Debug.print("Cannot create new bucket: " # e);
                        return #err("Cannot create new bucket");
                    }
                };
            } catch (e) {
                Debug.print("Cannot create new bucket: " # Error.message(e));
                return #err("Cannot create new bucket");
            }
        };

        #ok(respBucketPrincipal)
    };
}