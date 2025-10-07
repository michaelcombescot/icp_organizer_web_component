shared ({ caller = owner }) persistent actor class TodosBucket() = this {
    
}

    // public shared ({ caller }) func createTodo(userPrincipal: Principal, todo: Todo.Todo) : async Result.Result<(), [Text]> {
    //     if ( Configs.CanisterIds.INDEX_TODO_CANISTER != Principal.toText(caller) ) { return #err(["can only be called by the index todo canister"]); };

    //     let ?userData = Map.get(usersData, Principal.compare, userPrincipal) else return #err(["No user data"]);

    //     Map.add(userData.todos, Nat.compare, todo.id, todo);

    //     #ok
    // };

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