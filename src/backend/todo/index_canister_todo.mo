import Text "mo:base/Text";
import Map "mo:core/Map";
import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Option "mo:base/Option";
import Todo "./model";
import MapCore "mo:core/Map";
import Array "mo:core/Array";
import Nat "mo:core/Nat";
import Nat32 "mo:core/Nat32";
import Cycles "mo:base/ExperimentalCycles";
import TodoBucket "./bucket_todo";
import Model "model";
import Helpers "../helpers/helpers";

persistent actor {
    let MAX_NB_USERS_PER_CANISTER = 10_000;
    let NEW_BUCKET_NB_CYCLES = 1_000_000_000;
    
    var lastTodoId = 0;

    //
    // QUERY DATA
    //

    // map an object id with the owner principal
    var todosOwners     = Map.empty<Nat, Principal>();
    var todoListsOwners = Map.empty<Nat, Principal>();

    //
    // BUCKETS
    //

    var currentBucketData: {bucket: ?TodoBucket.TodoBucket; nbUsers: Nat} = {bucket = null; nbUsers = 0;};
    var principalsOnBuckets = Map.empty<Principal, TodoBucket.TodoBucket>();

    //
    // USER 
    //

    // call this function when a user connect, create the bucket for the user if it doesn't exist
    public shared ({ caller }) func createUser() : async Result.Result<(), Text> {
        if ( Principal.isAnonymous(caller) ) { return #err("Not logged in"); };

        switch ( Map.get(principalsOnBuckets, Principal.compare, caller) ) {
            case null {
                if ( Option.isNull(currentBucketData.bucket) or currentBucketData.nbUsers >= MAX_NB_USERS_PER_CANISTER ) { // create a new bucket
                    Cycles.add(NEW_BUCKET_NB_CYCLES);
                    let bucket = await TodoBucket.TodoBucket();
                    currentBucketData := { bucket = ?bucket; nbUsers = 0; };
                } else {
                    currentBucketData := {currentBucketData with nbUsers = currentBucketData.nbUsers + 1;};
                };

                let ?bucket = currentBucketData.bucket else return #err("No current bucket");

                Map.add( principalsOnBuckets, Principal.compare, caller, bucket );
                
                switch ( await bucket.createUserData(caller) ) {
                    case (#ok) #ok;
                    case (#err err) return #err(err);
                }
            };
            case (?_) #ok;
        }
    };

    public query ({ caller }) func getAllDataForUser() : async Result.Result<[Model.Todo.Todo], Text> {
        if ( Principal.isAnonymous(caller) ) { return #err("Not logged in"); };

        // TODO

        #ok([])
    };

    //
    // TODO
    //

    public shared ({ caller }) func createTodo(todo: Model.Todo.Todo) : async Result.Result<Nat, Text> {
        if ( Principal.isAnonymous(caller) ) { return #err("Not logged in"); };

        let listOwner = Map.get(todosOwners, Nat.compare, ?todo.todoListId);
        let ?ownerBucket    = Map.get(todosBucketsIndexes, Nat.compare, ?todo.id) else return #err("No index for this todo");

        if ( Option.isSome(todo.todoListId) and ?listOwner != caller ) {
            switch ( await ownerBucket.getPermissionForList({owner = ?listOwner; user = caller; listId = ?todo.todoListId}) ) {
                case (#ok listPermission) if ( listPermission != #write ) { return #err("No write permission"); };
                case (#err err) #err(err);
            }
        };

        let todoWithId = { todo with id = lastTodoId + 1 };

        switch ( await ownerBucket.createTodo({principal = listOwner; todo = todoWithId}) ) {
            case (#ok) {
                Map.add(todosOwners, Nat.compare, todoWithId.id, listOwner);

                #ok(todoWithId.id);
            };
            case (#err err) return #err(err);
        }
    };

    public shared ({ caller }) func updateTodo(todo: Model.Todo.Todo) : async Result.Result<(), Text> {
        if ( Principal.isAnonymous(caller) ) { return #err("Not logged in"); };

        let ?bucket = getBucketForPrincipal(caller) else return #err("No bucket for user");

        switch ( await bucket.getPrincipalForTodo(todo.id) ) {
            case (#ok todoPermissions) {
                if ( todoPermissions != #owned and todoPermissions != #owned ) { return #err("No write permission"); };
            };
            case (#err err) return #err(err);
        };

        let ?todoBucket = Map.get(todoBuckets, Nat.compare, getIndexForTodoBucket(todo.id)) else return #err("No todo bucket");
        switch (await todoBucket.updateTodo(todo)) { case (#ok) (); case (#err err) return #err(err); };

        #ok
    };

    // public shared ({ caller }) func removeTodo(id: Nat) : async Result.Result<(), Text> {
    //     if ( Principal.isAnonymous(caller) ) { return #err("Not logged in"); };

    //     let ?userDataBucket = Map.get(userTodoDataBuckets, Nat32.compare, Principal.hash(caller)) else return #err("No user bucket");
    //     switch ( await userDataBucket.getTodoPermission(id) ) {
    //         case (#ok todoPermissions) {
    //             if ( todoPermissions != #owned and todoPermissions != #owned ) { return #err("No write permission"); };
    //         };
    //         case (#err err) return #err(err);
    //     };

    //     let ?todoBucket = Map.get(todoBuckets, Nat.compare, getIndexForTodoBucket(id)) else return #err("No todo bucket");
    //     switch (await todoBucket.removeTodo(id)) { case (#ok) (); case (#err err) return #err(err); };

    //     #ok
    // };

    // /////
    // // TODO LIST INTERFACE
    // /////

    // public query ({ caller }) func getTodoLists() : async Result.Result<[TodoList.TodoList], Text> {
    //     if ( Principal.isAnonymous(caller) ) { return #err("Not logged in"); };

    //     //TODO

    //     #ok([])
    // };

    // public shared ({ caller }) func addTodoList(todoList: TodoList.TodoList) : async Result.Result<(), Text> {
    //     if ( Principal.isAnonymous(caller) ) { return #err("Not logged in"); };

    //     // TODO

    //     #ok
    // };

    // public shared ({ caller}) func updateTodoList(list: TodoList.TodoList) : async Result.Result<(), Text> {
    //     if ( Principal.isAnonymous(caller) ) { return #err("Not logged in"); };

    //     // TODO

    //     #ok
    // };

    // public shared ({ caller }) func removeTodoList(uuid: Text) : async Result.Result<(), Text> {
    //     if ( Principal.isAnonymous(caller) ) { return #err("Not logged in"); };

    //     // TODO

    //     #ok
    // };

    //
    // HELPERS LIST
    //
};

