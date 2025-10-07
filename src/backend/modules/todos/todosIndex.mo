import Principal "mo:core/Principal";
import Debug "mo:core/Debug";
import Map "mo:core/Map";
import Result "mo:core/Result";
import List "mo:core/List";
import Array "mo:core/Array";
import OrderedMap "mo:base/OrderedMap";
import Interfaces "../../shared/interfaces";
import TodosBucket "todosBucket";
import Configs "../../shared/configs";

type BucketData = {
    principal: Principal;
    bucket: TodosBucket.TodosBucket;
    nbEntries: Nat;
};

shared ({ caller = owner }) persistent actor class TodosIndex() = this {
    transient let bucketMapOperations = OrderedMap.Make<Principal>(Principal.compare);
    var bucketsStore = bucketMapOperations.empty<BucketData>();

    var todosOnBuckets = Map.empty<Principal, Principal>();

    public shared ({ caller }) func getorCreateBucket(todoPrincipal: Principal, bucketPrincipal: Principal) : async Result.Result<Principal, Text> {
        func createBucket() : async Principal {
            let bucket = await (with cycles = Configs.Consts.NEW_BUCKET_NB_CYCLES) TodosBucket.TodosBucket();
            let bucketprincipal = Principal.fromActor(bucket);
            bucketsStore := bucketMapOperations.put(bucketsStore, bucketprincipal, { principal = bucketprincipal; bucket = bucket; nbEntries = 0; });
            
            bucketprincipal
        };

        var principalResponse = Principal.anonymous();
        switch (bucketMapOperations.maxEntry(bucketsStore)) {
            case (?(principal,bucket)) {
                principalResponse :=    if ( bucket.nbEntries >= Configs.Consts.BUCKET_TODOS_MAX_ENTRIES ) {
                                            await createBucket()
                                        } else {
                                            principal
                                        };
            };
            case null {
                principalResponse := await createBucket()
            };
        };

        #ok(principalResponse)
    };

    public query ({ caller }) func getBuckets(todos: [Principal]) : async Result.Result<[Principal], Text> {
        var bucketsPrincipals = List.empty<Principal>();

        for (todo in Array.values(todos)) {
            switch (Map.get(todosOnBuckets, Principal.compare, todo)) {
                case (?bucketPrincipal) {
                    List.add(bucketsPrincipals, bucketPrincipal);
                };
                case null return #err("No bucket for todo " # Principal.toText(todo));
            }
        };

        #ok(List.toArray(bucketsPrincipals));
    };
}