import Text "mo:base/Text";
import Map "mo:core/Map";
import Result "mo:core/Result";
import Principal "mo:base/Principal";
import Option "mo:base/Option";
import List "mo:core/List";
import Nat "mo:core/Nat";
import BucketUsersData "./buckets/bucketUsersData";
import Todo "./models/todo";
import TodoList "./models/todoList";
import User "models/user";
import Interfaces "../../helpers/interfaces";
import Debug "mo:core/Debug";
import Nat64 "mo:core/Nat64";
import Time "mo:core/Time";
import Error "mo:core/Error";

persistent actor {
    let NEW_BUCKET_NB_CYCLES = 2_000_000_000_000;
    let NB_CYCLES_MIN_BEFORE_TOPPING = 1_000_000_000_000;
    let TOP_UP_AMOUNT = 1_000_000_000_000;
    let TOP_UP_TIMER_INTERVAL_NS = 20_000_000_000;
    let BUCKET_USERS_DATA_MAX_ENTRIES = 1000;

    //
    // BUCKETS
    //

    var bucketUsersData: {var bucket: ?BucketUsersData.BucketUsersData; var nbUsers: Nat} =  { var bucket = null; var nbUsers = 0; };    

    //
    // MAPPINGS
    //

    var listOfBucketsUserDataPrincipals     = List.empty<Principal>();
    var principalsOnBuckets                 = Map.empty<Principal, BucketUsersData.BucketUsersData>();

    //
    // INC
    //

    var lastTodoId      = 0;
    var lastTodoListId  = 0;
    var lastGroupId     = 0;

    //
    // CANISTERS
    //

    let managementCanister = actor("aaaaa-aa") : Interfaces.Self;

    //
    // SYSTEM
    //

    // system func heartbeat() : async () { => is a function automatically pocket every second or so by the system

    // timer launch when the actor is started, and then at a time defined with setGlobalTimer.
    // Here it will top up all buckets if needed, and be called againa after a cooldown of TOP_UP_TIMER_INTERVAL_NS
    system func timer(setGlobalTimer: (Nat64) -> ()) : async () {
        for ( bucketPrincipal in List.values(listOfBucketsUserDataPrincipals) ) {
            let status = await managementCanister.canister_status({ canister_id = bucketPrincipal });

            if ( status.cycles < NB_CYCLES_MIN_BEFORE_TOPPING ) {
                Debug.print("Topping bucket " # Principal.toText(bucketPrincipal));
                ignore (with cycles = TOP_UP_AMOUNT) managementCanister.deposit_cycles({ canister_id = bucketPrincipal });
            };
        };

        setGlobalTimer( Nat64.fromIntWrap(Time.now()) + Nat64.fromNat(TOP_UP_TIMER_INTERVAL_NS) ); // + 20s
    };

    public shared func upgradeAllBuckets() : async () {
        // update users buckets
        label l for (p in List.values(listOfBucketsUserDataPrincipals)) {
            try {
                await managementCanister.stop_canister({ canister_id = p });
            } catch (e) {
                Debug.print("Cannot stop UserData bucket " # Principal.toText(p) # ": " # Error.message(e));
                continue l;
            };

            let userDataBucket = actor (Principal.toText(p)) : BucketUsersData.BucketUsersData;

            try {
                ignore await (system BucketUsersData.BucketUsersData)(#upgrade userDataBucket)();
            } catch (e) {
                Debug.print("Cannot upgrade UserData bucket " # Principal.toText(p) # ": " # Error.message(e));
                continue l;
            };

            try {
                await managementCanister.start_canister({ canister_id = p });
            } catch (e) {
                Debug.print("Cannot restart UserData bucket" # Principal.toText(p) # ": " # Error.message(e));
            };
        };
    };

    //
    // USER 
    //

    // call this function when a user connect, create the bucket for the user if it doesn't exist.
    func getOrCreateUserBucket(caller: Principal) : async Result.Result<BucketUsersData.BucketUsersData, Text> {
        if ( Principal.isAnonymous(caller) ) { return #err("Not logged in"); };

        switch( Map.get(principalsOnBuckets, Principal.compare, caller) ) {
            case (?bucket) return #ok(bucket);
            case null ();
        };

        if ( Option.isNull(bucketUsersData.bucket)  or bucketUsersData.nbUsers >= BUCKET_USERS_DATA_MAX_ENTRIES ) { // create a new bucket
            let bucket = await (with cycles = NEW_BUCKET_NB_CYCLES) BucketUsersData.BucketUsersData();
            List.add(listOfBucketsUserDataPrincipals, Principal.fromActor(bucket));
            bucketUsersData.bucket := ?bucket;
        };

        let ?bucket = bucketUsersData.bucket else return #err("No bucket");
        Map.add( principalsOnBuckets, Principal.compare, caller, bucket );

        switch ( await bucket.createUserData(caller) ) {
            case (#ok) {
                bucketUsersData.nbUsers := bucketUsersData.nbUsers + 1; 
                #ok(bucket);
            };
            case (#err err) #err(err);
        }
    };

    public shared ({ caller }) func getuserData() : async Result.Result<User.UserDataSharable, Text> {
        if ( Principal.isAnonymous(caller) ) { return #err("Not logged in"); };

        let bucket = switch ( await getOrCreateUserBucket(caller) ) { case (#ok bucket) bucket; case (#err err) return #err(err); };

        switch ( await bucket.getUserData(caller) ) {
            case (#ok data) #ok(data);
            case (#err err) #err(err);
        }
    };

    //
    // TODO
    //

    public shared ({ caller }) func createTodo(todo: Todo.Todo) : async Result.Result<Nat, [Text]> {
        if ( Principal.isAnonymous(caller) ) { return #err(["Not logged in"]); };

        switch ( Todo.validateTodo(todo) ) { case (#ok) (); case (#err err) return #err(err); };

        let todoWithId = { todo with id = lastTodoId + 1; };

        let ?bucket = Map.get(principalsOnBuckets, Principal.compare, caller) else return #err(["No bucket"]);

        switch ( await bucket.createTodo(caller, todoWithId) ) {
            case (#ok) {
                lastTodoId := lastTodoId + 1;
                #ok(todoWithId.id)
            };
            case (#err err) #err(err);
        }
    };

    public shared ({ caller }) func updateTodo(todo: Todo.Todo) : async Result.Result<(), [Text]> {
        if ( Principal.isAnonymous(caller) ) { return #err(["Not logged in"]); };

        switch ( Todo.validateTodo(todo) ) { case (#ok) (); case (#err err) return #err(err); };

        let ?bucket = Map.get(principalsOnBuckets, Principal.compare, caller) else return #err(["No bucket"]);

        switch ( await bucket.updateTodo(caller, todo) ) {
            case (#ok) #ok;
            case (#err err) #err(err);
        }
    };

    public shared ({ caller }) func removeTodo(todoId: Nat) : async Result.Result<(), [Text]> {
        if ( Principal.isAnonymous(caller) ) { return #err(["Not logged in"]); };

        let ?bucket = Map.get(principalsOnBuckets, Principal.compare, caller) else return #err(["No bucket"]);

        switch ( await bucket.removeTodo(caller, todoId) ) {
            case (#ok) #ok;
            case (#err err) #err(err);
        }
    };

    //
    // TODO LIST
    //

    public shared ({ caller }) func createTodoList(todoList: TodoList.TodoList) : async Result.Result<Nat, [Text]> {
        if ( Principal.isAnonymous(caller) ) { return #err(["Not logged in"]); };

        switch ( TodoList.validateTodoList(todoList) ) { case (#ok) (); case (#err err) return #err(err); };

        let todoListWithId = { todoList with id = lastTodoListId + 1; };

        let ?bucket = Map.get(principalsOnBuckets, Principal.compare, caller) else return #err(["No bucket"]);

        switch ( await bucket.createTodoList(caller, todoListWithId) ) {
            case (#ok) {
                lastTodoListId := lastTodoListId + 1;
                #ok(todoListWithId.id);
            };
            case (#err err) #err(err);
        }
    };

    public shared ({ caller }) func updateTodoList(todoList: TodoList.TodoList) : async Result.Result<(), [Text]> {
        if ( Principal.isAnonymous(caller) ) { return #err(["Not logged in"]); };

        switch ( TodoList.validateTodoList(todoList) ) { case (#ok) (); case (#err err) return #err(err); };

        let ?bucket = Map.get(principalsOnBuckets, Principal.compare, caller) else return #err(["No bucket"]);

        switch ( await bucket.updateTodoList(caller, todoList) ) {
            case (#ok) #ok;
            case (#err err) #err(err);
        }
    };

    public shared ({ caller }) func removeTodoList(todoListId: Nat) : async Result.Result<(), [Text]> {
        if ( Principal.isAnonymous(caller) ) { return #err(["Not logged in"]); };

        let ?bucket = Map.get(principalsOnBuckets, Principal.compare, caller) else return #err(["No bucket"]);

        switch ( await bucket.removeTodoList(caller, todoListId) ) {
            case (#ok) #ok;
            case (#err err) #err(err);
        }
    };
};

