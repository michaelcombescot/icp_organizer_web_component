import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Text "mo:core/Text";
import Time "mo:core/Time";
import Map "mo:core/Map";
import Array "mo:core/Array";
import Nat64 "mo:core/Nat64";
import Runtime "mo:core/Runtime";
import List "mo:core/List";
import Blob "mo:core/Blob";
import TodosUsersDataBucket "buckets/todosUsersDataBucket";
import TodosGroupsBucket "buckets/todosGroupsBucket";
import CanistersKinds "../ops/canistersKinds";
import Interfaces "../shared/interfaces";
import TodoModel "models/todoModel";
import TodoListModel "models/todoListModel";
import GroupModel "models/groupModel";
import UserDataModel "models/userDataModel";

shared ({ caller = owner }) persistent actor class TodosIndex() = this {
    ////////////
    // CONFIG //
    ////////////

    let TIMER_INTERVAL_NS: Nat64 = 60_000_000_000;

    ////////////
    // ERRORS //
    ////////////

    type ErrorInterCanisterCall = {
        #errorCannotFetchNewBucket: CanistersKinds.BucketTodoKind;
    };

    ////////////
    // MEMORY //
    ////////////

    let coordinator = actor(Principal.toText(owner)) : Interfaces.Coordinator;

    let memoryBucketsUsersData = Map.empty<Principal, TodosUsersDataBucket.TodosUsersDataBucket>();
    let memoryBucketsGroups = Map.empty<Principal, TodosGroupsBucket.TodosGroupsBucket>();

    let currentUsersDataBucket = actor(Principal.toText(owner)) : TodosUsersDataBucket.TodosUsersDataBucket;
    let currentGroupsBucket = actor(Principal.toText(owner)) : TodosGroupsBucket.TodosGroupsBucket;

    ////////////
    // SYSTEM //
    ////////////

    type Msg = {
        #createNewUser : () -> (todo : TodoModel.Todo);
    };

    system func inspect({ arg : Blob; caller : Principal; msg : Msg }) : Bool {
        // check if the user is connected
        if (Principal.isAnonymous(caller)) { return false; };

        // check payload size
        if (Blob.size(arg) > 1000) { return false; };

        true
    };

    system func timer(setGlobalTimer : (Nat64) -> ()) : async () {
        // ???????

        setGlobalTimer(Nat64.fromIntWrap(Time.now()) + TIMER_INTERVAL_NS);
    };

    ///////////
    // USERS //
    ///////////

    // Create a new user.
    // a user is a group with a single associated principal.
    public shared ({ caller }) func createNewUser() : async Result.Result<{ userBucket: Principa; groupBucket: Principal }, Text> {
        // 1) find right user buckets
        // 2) create a new entry in a groups bucket
        // 3) return the buckets principal for both uses buckets
    };

    ////////////
    // GROUPS //
    ////////////
}