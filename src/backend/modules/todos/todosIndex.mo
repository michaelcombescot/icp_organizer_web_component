import Principal "mo:core/Principal";
import Debug "mo:core/Debug";
import Result "mo:core/Result";
import Error "mo:core/Error";
import Text "mo:core/Text";
import Int "mo:core/Int";
import OrderedMap "mo:base/OrderedMap";
import Interfaces "../../shared/interfaces";
import Configs "../../shared/configs";
import Errors "../../shared/errors";
import Todo "todoModel";
import TodosBucket "todosBucket";

shared ({ caller = owner }) persistent actor class TodosIndex() = this {
    transient let bucketMapOperations = OrderedMap.Make<Int>(Int.compare);
    var bucketsStore = bucketMapOperations.empty<TodosBucket.TodosBucket>();

    //
    // API 
    //

    // create a new todo in the last created bucket.
    // trigger the creation of a new bucket if the last one is full
    // return the id of the created todo
    public shared ({ caller }) func createTodo(todo: Todo.Todo) : async Result.Result<Text, [Text]> {
        if ( caller == Principal.anonymous() ) { return #err([Errors.ERR_NOT_CONNECTED]); };

        if (bucketsStore.size == 0) { await createNewBucket(Int.fromNat(0)); };

        switch ( bucketMapOperations.maxEntry(bucketsStore) ) {
            case (?(_, bucketAktor)) {
                switch ( await bucketAktor.createTodo(caller, todo) ) {
                    case (#ok( (timestamp, todoId, nbEntries) )) {
                        if ( nbEntries > Configs.Consts.BUCKET_TODOS_MAX_ENTRIES ) {
                            await createNewBucket(timestamp);
                        };

                        return #ok(todoId);
                    };
                    case (#err(e)) return #err(e);
                };
            };
            case (null) return #err([Errors.ERR_NO_BUCKET_FOUND]);
        }
    };

    //
    // PRIVATE
    //

    // create a new bucket and update the bucket store
    // it should not be necessary to do more than that to have something fiable, because even if one creation failed, next one will probably succeed.
    // only risk is to have too many todos in a single specific bucket but it should almost never happened
    func createNewBucket(maxTimestamp: Int) : async () {
        try {
            switch ( await Interfaces.MaintenanceIndex.canister.addBucket() ) {
                case (#ok(bucketPrincipal)) bucketsStore := bucketMapOperations.put(bucketsStore, maxTimestamp, actor (Principal.toText(bucketPrincipal)) : TodosBucket.TodosBucket);
                case (#err(e)) Debug.print("Cannot create new bucket: " # e);
            };
        } catch (e) {
            Debug.print("Cannot create new bucket: " # Error.message(e));
        };
    };
}