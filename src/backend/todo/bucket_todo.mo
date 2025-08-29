import Map "mo:core/Map";
import Nat "mo:base/Nat";
import Array "mo:base/Array";
import Principal "mo:base/Principal";
import Model "./model";
import Result "mo:base/Result";

persistent actor class TodoBucket() {
    //
    // CONSTANTS
    //

    let indexCanisterPrincipal: Principal = Principal.fromText("2vxsx-fae");

    /////
    // memory declarations
    /////

    var storeTodos = Map.empty<Nat, Model.Todo.Todo>();

    /////
    // Interface
    /////

    public query ({ caller }) func getTodos(todosIds: [Nat]) : async (Result.Result<[Model.Todo.Todo], Text>) {
        if (callerIsNotIndexCanister(caller)) { return #err("Caller is not the index canister"); };

        let todos = Array.mapFilter(todosIds, func(id: Nat) : ?Model.Todo.Todo {
            switch (Map.get(storeTodos, Nat.compare, id)) {
                case null null;
                case (?todo) ?todo;
            }
        });

        #ok(todos)
    };

    public shared ({ caller }) func addTodo(todo: Model.Todo.Todo) : async Result.Result<(), Text> {
        if (callerIsNotIndexCanister(caller)) { return #err("Caller is not the index canister"); };

        let ?_ = Map.get(storeTodos, Nat.compare, todo.id) else return #err("Todo already exists");

        Map.add(storeTodos, Nat.compare, todo.id, todo);

        #ok
    };

    public shared ({ caller }) func updateTodo(todo: Model.Todo.Todo) : async Result.Result<(), Text> {
        if (callerIsNotIndexCanister(caller)) { return #err("Caller is not the index canister"); };

        let ?_ = Map.get(storeTodos, Nat.compare, todo.id) else return #err("Todo does not exist");

        Map.add(storeTodos, Nat.compare, todo.id, todo);

        #ok
    };

    public shared ({ caller }) func removeTodo(id: Nat) : async Result.Result<(), Text> {
        if (callerIsNotIndexCanister(caller)) { return #err("Caller is not the index canister"); };

        Map.remove(storeTodos, Nat.compare, id);

        #ok
    };

    //
    // HELPERS
    //

    func callerIsNotIndexCanister(caller: Principal) : Bool {
        return caller != indexCanisterPrincipal;
    };
}