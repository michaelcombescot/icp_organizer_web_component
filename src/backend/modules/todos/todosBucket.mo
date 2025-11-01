import Todo "todoModel";
import Result "mo:core/Result";
import Map "mo:core/Map";
import Principal "mo:core/Principal";
import Text "mo:core/Text";
import Time "mo:core/Time";
import Array "mo:core/Array";
import List "mo:core/List";
import Nat "mo:core/Nat";
import GroupsBucket "../groups/groupsBucket";

shared ({ caller = owner }) persistent actor class TodosBucket(indexPrincipal: Principal) = this {
    let index = indexPrincipal;
    let storeTodos = Map.empty<Text, Todo.Todo>();

    public shared ({ caller }) func createTodo(owner: Todo.TodoOwner, todo: Todo.Todo) : async Result.Result<(Text, Nat), [Text]> {
        if ( caller != index ) { return #err(["can only be called by the index todo canister"]); };

        switch ( Todo.validateTodo(todo) ) {
            case (#ok(_)) ();
            case (#err(e)) return #err(e);
        };

        let now = Time.now();
        let id = Principal.toText(Principal.fromActor(this)) # "_" # Nat.toText(Map.size(storeTodos));

        Map.add(storeTodos, Text.compare, id, { todo with id = id; owner = owner; createdAt = now; });

        #ok(id, Map.size(storeTodos))
    };

    public shared ({ caller }) func getTodos(ids: [Text]) : async Result.Result<[Todo.Todo], Text> {
        var todos           = List.empty<Todo.Todo>();
        var groupsToCheck   = Map.empty<Text, Text>(); // store bucket id/group id

        for (id in Array.values(ids)) {
            switch (Map.get(storeTodos, Text.compare, id)) {
                case (?todo) {
                    switch(todo.owner) {
                        case(#user(principal)) if ( principal != caller ) { return #err("can only be retrieved by the todo owner") };
                        case(#group(id)) {
                            // check if user belongs to the group
                            let ?firstPart = ( Text.split(id, #char '_') ).next() else return #err("malformed group id");
                            Map.add(groupsToCheck, Text.compare, firstPart, id);
                        };
                    };

                    List.add(todos, todo);
                };
                case (null) return #err("todo wit id " # id # " not found");
            }
        };

        if ( Map.size(groupsToCheck) != 0 ) {
            let futures = List.empty<async Bool>();
            for ( (bucketPrincipal, groupId) in Map.entries(groupsToCheck)) {
                List.add(futures, (actor (bucketPrincipal) : GroupsBucket.GroupsBucket).isUserInGroup(groupId, caller));
            };

            for (future in List.values(futures)) {
                if ( not (await future) ) { return #err("user does not belong to the group"); };
            };
        };

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