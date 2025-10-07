 // public shared ({ caller }) func createTodoList(userPrincipal: Principal, todoList: TodoList.TodoList) : async Result.Result<(), [Text]> {
    //     if ( Configs.CanisterIds.INDEX_TODO_CANISTER != Principal.toText(caller) ) { return #err(["can only be called by the index todo canister"]); };

    //     let ?userData = Map.get(usersData, Principal.compare, userPrincipal) else return #err(["No user data"]);

    //     Map.add(userData.todoLists, Nat.compare, todoList.id, todoList);

    //     #ok
    // };

    // public shared ({ caller }) func updateTodoList(userPrincipal: Principal, todoList: TodoList.TodoList) : async Result.Result<(), [Text]> {
    //     if ( Configs.CanisterIds.INDEX_TODO_CANISTER != Principal.toText(caller) ) { return #err(["can only be called by the index todo canister"]); };

    //     let ?userData = Map.get(usersData, Principal.compare, userPrincipal) else return #err(["No user data"]);

    //     let _ = Map.swap(userData.todoLists, Nat.compare, todoList.id, todoList) else return #err(["No todo list found"]);

    //     #ok
    // };

    // // remove the list and all associated todos
    // public shared ({ caller }) func removeTodoList(userPrincipal: Principal, todoListId: Nat) : async Result.Result<(), [Text]> {
    //     if ( Configs.CanisterIds.INDEX_TODO_CANISTER != Principal.toText(caller) ) { return #err(["can only be called by the index todo canister"]); };

    //     let ?userData = Map.get(usersData, Principal.compare, userPrincipal) else return #err(["No user data"]);

    //     Map.remove(userData.todoLists, Nat.compare, todoListId);

    //     Iter.forEach( Map.entries(userData.todos), func ((_, todo)) { if ( todo.todoListId == ?todoListId ) { Map.remove(userData.todos, Nat.compare, todo.id) } } );

    //     #ok
    // };