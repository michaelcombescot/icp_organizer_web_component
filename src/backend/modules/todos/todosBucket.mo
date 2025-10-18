import Todo "todoModel";
import Result "mo:core/Result";
import Map "mo:core/Map";
import Configs "../../shared/configs";
import Principal "mo:core/Principal";
import Text "mo:core/Text";
import Time "mo:core/Time";
import Array "mo:core/Array";
import List "mo:core/List";
import Int "mo:base/Int";

shared ({ caller = owner }) persistent actor class TodosBucket() = this {
    let todosStore = Map.empty<Text, Todo.Todo>();

    public shared ({ caller }) func createTodo(userPrincipal: Principal, todo: Todo.Todo) : async Result.Result<(Int, Text, Nat), [Text]> {
        if ( Configs.CanisterIds.INDEX_TODOS != Principal.toText(caller) ) { return #err(["can only be called by the index todo canister"]); };

        switch ( Todo.validateTodo(todo) ) {
            case (#ok(_)) ();
            case (#err(e)) return #err(e);
        };

        let now = Time.now();
        let id = Principal.toText(Principal.fromActor(this)) # "-" # Int.toText(now);

        Map.add(todosStore, Text.compare, id, { todo with id = id; owner = userPrincipal; createdAt = now; });

        #ok( now, id, Map.size(todosStore))
    };

    public shared ({ caller }) func getTodos(ids: [Text]) : async Result.Result<[Todo.Todo], [Text]> {
        var errors = List.empty<Text>();
        var todos = List.empty<Todo.Todo>();
        
        for (id in Array.values(ids)) {
            switch (Map.get(todosStore, Text.compare, id)) {
                case (?todo) {
                    if ( todo.owner != caller ) {
                        List.add(errors, "can only be retrieved by the todo owner") 
                    } else {
                        List.add(todos, todo);
                    };
                };
                case (null) List.add(errors, "todo wit id " # id # " not found");
            }
        };

        if ( List.size(errors) != 0 ) { return #err( List.toArray(errors) ) };

        #ok(List.toArray(todos))
    };
}

    // public shared ({ caller }) func updateTodo(userPrincipal: Principal, todo: Todo.Todo) : async Result.Result<(), [Text]> {
    //     if ( Configs.CanisterIds.INDEX_TODO_CANISTER != Principal.toText(caller) ) { return #err(["can only be called by the index todo canister"]); };

    //     let ?userData = Map.get(usersData, Principal.compare, userPrincipal) else return #err(["No user data"]);

    //     let _ = Map.swap(userData.todos, Nat.compare, todo.id, todo) else return #err(["No todo found"]);

    //     #ok
    // };

    // public shared ({ caller }) func removeTodo(userPrincipal: Principal, todoId: Nat) : async Result.Result<(), [Text]> {
    //     if ( Configs.CanisterIds.INDEX_TODO_CANISTER != Principal.toText(caller) ) { return #err(["can only be called by the index todo canister"]); };

    //     let ?userData = Map.get(usersData, Principal.compare, userPrincipal) else return #err(["No user data"]);

    //     Map.remove(userData.todos, Nat.compare, todoId);

    //     #ok
    // };