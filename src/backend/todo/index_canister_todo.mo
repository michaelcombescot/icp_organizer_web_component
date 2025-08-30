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

persistent actor {
    //
    // VARIABLES
    //

    let newCanisterNumberCycle = 1_000_000_000;

    var lastTodoId = 0;
    var lastTodoListID = 0;
    
    //
    // BUCKETS
    //

    var todoBuckets = Map.empty<Nat32, TodoBucket.TodoBucket>();

    //
    // QUERIES
    //

    public shared ({ caller }) func getUserTodosWithLists() : async ([Model.Todo.Todo]) {
        if ( Principal.isAnonymous(caller) ) { return []; };

        // retrieve user todos data
        let ?userDataBucket = Map.get(userTodoDataBuckets, Nat32.compare, Principal.hash(caller)) else return [];
        let todosData = switch ( await userDataBucket.getCallerTodosWithPermissions(caller) ) { case (#ok todos) todos; case (#err err) return #err("cannot get user data: " # err); };

        // find all buckets for user todos
        var todoBucketsIndexes = Array.map(todosData, func(data: (Nat, Todo.Todo.Permissions)) : Nat {
            return getIndexForTodoBucket(data.0);
        });
        todoBucketsIndexes := Helpers.ArrayHelpers.removeDuplicates<Nat>(todoBuckets, Nat.compare);

        let todoCalls = Array.map(todoBucketsIndexes, func(index: Nat) : async ([Model.Todo.Todo]) {
            let bucket = Map.get(todoBuckets, Nat.compare, index) else return null;
            bucket.getTodos();
        });

        
    };

    // public shared ({ caller }) func createTodo(todo: Model.Todo.Todo) : async Result.Result<Nat, Text> {
    //     if ( Principal.isAnonymous(caller) ) { return #err("Not logged in"); };

    //     let todoWithId = { todo with id = lastTodoId + 1 };

    //     //add todo
    //     let todoBucket = switch ( await getOrCreateTodoBucket(todoWithId.id)) { case (#ok bucket) bucket; case (#err err) return #err(err); };
    //     switch ( await todoBucket.addTodo(todoWithId) ) {
    //         case (#ok) lastTodoId += 1;
    //         case (#err err) return #err(err);
    //     };

    //     // save link between todo and user
    //     let userBucket = switch ( await getOrCreateUserDataBucket(caller)) { case (#ok bucket) bucket; case (#err err) return #err(err); };
    //     switch ( await userBucket.createTodoForUser(todoWithId.id) ) { case (#ok) (); case (#err err) return #err(err); };

    //     #ok(todoWithId.id)
    // };

    // public shared ({ caller }) func updateTodo(todo: Todo.Todo) : async Result.Result<(), Text> {
    //     if ( Principal.isAnonymous(caller) ) { return #err("Not logged in"); };

    //     let ?userDataBucket  = Map.get(userTodoDataBuckets, Nat32.compare, Principal.hash(caller)) else return #err("No user bucket");
    //     switch ( await userDataBucket.getTodoPermission(todo.id) ) {
    //         case (#ok todoPermissions) {
    //             if ( todoPermissions != #owned and todoPermissions != #owned ) { return #err("No write permission"); };
    //         };
    //         case (#err err) return #err(err);
    //     };

    //     let ?todoBucket = Map.get(todoBuckets, Nat.compare, getIndexForTodoBucket(todo.id)) else return #err("No todo bucket");
    //     switch (await todoBucket.updateTodo(todo)) { case (#ok) (); case (#err err) return #err(err); };

    //     #ok
    // };

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

    // /////
    // // helpers
    // /////

    // // func canUpdateTodo(caller: Principal, todo: Todo.Todo) : Bool {
    // //     let ?userBucketIndex    = Map.get(userTodoBucketsIndexes, Principal.compare, caller) else return #err("No user bucket index");
    // //     let userBucket          = userTodoBuckets[userBucketIndex] else return #err("No user bucket");
    // //     let canEdit             = await userBucket.geTodoPermission(todo.id);

    // //     switch 

    // //     return canEdit.write;
    // // };

    // func getOrCreateUserDataBucket(caller: Principal) : async Result.Result<TodoUserBucket.TodoUserBucket, Text> {
    //     let principalHash = Principal.hash(caller);

    //     let bucket =    switch ( Map.get(userTodoDataBuckets, Nat32.compare, principalHash) ) {
    //                         case null {
    //                             Cycles.add(newCanisterNumberCycle);
    //                             let newBucket = await TodoUserBucket.TodoUserBucket();
    //                             Map.add(userTodoDataBuckets, Nat32.compare, principalHash, newBucket);
    //                             newBucket
    //                         };
    //                         case (?bucket) bucket;
    //                     };

    //     #ok(bucket)
    // };

    // func getIndexForTodoBucket(id: Nat) : Nat {
    //     id % 10000
    // };

    // func getOrCreateTodoBucket(id: Nat) : async Result.Result<TodoBucket.TodoBucket, Text> {
    //     let index = getIndexForTodoBucket(id);
    //     let bucket =    switch ( Map.get(todoBuckets, Nat.compare, index) ) {
    //                         case null {
    //                             Cycles.add(newCanisterNumberCycle);
    //                             let newBucket = await TodoBucket.TodoBucket();
    //                             Map.add(todoBuckets, Nat.compare, index, newBucket);
    //                             newBucket
    //                         };
    //                         case (?bucket) bucket
    //                     };

    //     #ok(bucket)
    // };
}

