import Principal "mo:core/Principal";
import Debug "mo:core/Debug";
import Result "mo:core/Result";
import Error "mo:core/Error";
import Text "mo:core/Text";
import Int "mo:core/Int";
import Time "mo:core/Time";
import List "mo:core/List";
import Map "mo:core/Map";
import Identifiers "../shared/identifiers";
import TodosTodosBucket "buckets/todosTodosBucket";
import TodosUsersDataBucket "buckets/todosUsersDataBucket";
import TodosGroupsBucket "buckets/todosGroupsBucket";
import TodosListsBucket "buckets/todosListsBucket";
import CanistersKinds "../ops/canistersKinds";

shared ({ caller = owner }) persistent actor class TodosIndex() = this {
    transient let ERR_CAN_ONLY_BE_CALLED_BY_OWNER = "ERR_CAN_ONLY_BE_CALLED_BY_OWNER";

    ////////////
    // CONFIG //
    ////////////

    transient let CONFIG_INTERVAL_FETCH_INDEXES: Nat64    = 20_000_000_000;

    ////////////
    // ERRORS //
    ////////////

    transient let ERR_NOT_CONNECTED = "ERR_NOT_CONNECTED";

    ////////////
    // MEMORY //
    ////////////

    transient let memoryTodosTodosBuckets           = Map.empty<Principal, TodosTodosBucket.TodosTodosBucket>();
    transient let memoryTodosUsersDataBuckets       = Map.empty<Principal, TodosUsersDataBucket.TodosUsersDataBucket>();
    transient let memoryTodosGroupsBuckets          = Map.empty<Principal, TodosGroupsBucket.TodosGroupsBucket>();
    transient let memoryTodosListsBuckets           = Map.empty<Principal, TodosListsBucket.TodosListsBucket>();

    transient let currentTodoBuckets                = ?TodosTodosBucket.TodosTodosBucket;
    transient let currentTodosUsersDataBucket       = ?TodosUsersDataBucket.TodosUsersDataBucket;
    transient let currentTodosGroupsBucket          = ?TodosGroupsBucket.TodosGroupsBucket;
    transient let currentTodosListsBucket           = ?TodosListsBucket.TodosListsBucket;

    ////////////
    // SYSTEM //
    ////////////

    public func requestNewBucket(bucketType : CanistersKinds.BucketKind) : () {
        
    }

    // public shared ({ caller }) func receiveBuckets(buckets: [(Buckets.BucketTodosType, [Principal])]) : () {
    //     if (caller != owner) { return };
        
    //     for (bucket in buckets) {
    //         List.add(storeBuckets[bucket[0]], bucket[1]);
    //     }
    // };

    ///////////
    // TODOS //
    ///////////

    
}