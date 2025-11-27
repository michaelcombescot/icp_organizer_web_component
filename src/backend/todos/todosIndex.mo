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
import Error "mo:core/Error";
import Debug "mo:base/Debug";
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

    var listAPIErrors = List.empty<ErrorInterCanisterCall>();

    ////////////
    // MEMORY //
    ////////////

    let coordinatorActor = actor(Principal.toText(owner)) : Interfaces.Coordinator;

    let memoryBucketsUsersData = Map.empty<Principal, TodosUsersDataBucket.TodosUsersDataBucket>();
    let memoryBucketsGroups = Map.empty<Principal, TodosGroupsBucket.TodosGroupsBucket>();

    var currentUsersDataBucket = actor(Principal.toText(owner)) : TodosUsersDataBucket.TodosUsersDataBucket;
    var currentGroupsBucket = actor(Principal.toText(owner)) : TodosGroupsBucket.TodosGroupsBucket;

    ////////////
    // SYSTEM //
    ////////////

    type Msg = {
        #addBucket : () -> { kind: CanistersKinds.BucketTodoKind; principal: Principal };

        #createNewUser : () -> ();
    };

    system func inspect({ arg : Blob; caller : Principal; msg : Msg }) : Bool {
        // check if the user is connected
        if (Principal.isAnonymous(caller)) { return false; };

        // check per route
        switch msg {
            case (#addBucket(_)) return caller == owner;
            case (#createNewUser(_)) return Blob.size(arg) > 1000;
        }
    };

    system func timer(setGlobalTimer : (Nat64) -> ()) : async () {
        // handling retry for errors
        let newErrors = List.empty<ErrorInterCanisterCall>();
        for (error in List.values(listAPIErrors)) {
            switch error {
                case (#errorCannotFetchNewBucket(bucketType)) {
                    try {
                        ignore await findNewCurrentBucket(bucketType);
                    } catch (e) {
                        Debug.print("Error while fetching new bucket: " # Error.message(e));
                        List.add(newErrors, error);
                    };
                };
            }      
        };

        listAPIErrors := newErrors;

        // reset timer
        setGlobalTimer(Nat64.fromIntWrap(Time.now()) + TIMER_INTERVAL_NS);
    };

    public shared func addBucket({ kind : CanistersKinds.BucketTodoKind; principal : Principal }) : async () {
        switch kind {
            case (#todosUsersDataBucket) Map.add(memoryBucketsUsersData, Principal.compare, principal, actor(Principal.toText(principal)) : TodosUsersDataBucket.TodosUsersDataBucket);
            case (#todosGroupsBucket) Map.add(memoryBucketsGroups, Principal.compare, principal, actor(Principal.toText(principal)) : TodosGroupsBucket.TodosGroupsBucket);
        };
    };

    ///////////
    // USERS //
    ///////////

    // Create a new user.
    // a user is a group with a single associated principal.
    public shared ({ caller }) func createNewUser() : async Result.Result<{ userBucket: Principal; groupBucket: Principal }, Text> {
        // 1) find right user buckets
        // 2) create a new entry in a groups bucket
        // 3) return the buckets principal for both uses buckets

        try {
            ignore coordinatorActor.handlerGiveFreeBucket({ nature = #todos(#todosUsersDataBucket) });
        } catch (e) {
            Debug.print("Error while fetching new bucket: " # Error.message(e));
            List.add(listAPIErrors, #errorCannotFetchNewBucket(#todosUsersDataBucket));
        };
        

        #err("not done")
    };

    ////////////
    // GROUPS //
    ////////////

    /////////////
    // HELPERS //
    /////////////

    func findNewCurrentBucket(bucketType: CanistersKinds.BucketTodoKind) : async Result.Result<(), Text> {
        let principal = try {
                            await coordinatorActor.handlerGiveFreeBucket({ nature = #todos(bucketType) });
                        } catch (e) {
                            return #err("Error while fetching new bucket: " # Error.message(e));
                        };

        switch bucketType {
            case (#todosUsersDataBucket) currentUsersDataBucket := actor(Principal.toText(principal)) : TodosUsersDataBucket.TodosUsersDataBucket;
            case (#todosGroupsBucket) currentGroupsBucket := actor(Principal.toText(principal)) : TodosGroupsBucket.TodosGroupsBucket;
        };

        #ok
    };
}