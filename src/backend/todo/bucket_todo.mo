import Map "mo:core/Map";
import Result "mo:core/Result";
import Principal "mo:core/Principal";
import Nat "mo:core/Nat";
import Iter "mo:core/Iter";
import Array "mo:core/Array";
import Option "mo:base/Option";
import Model "model";
import Helpers "helpers_todo";

persistent actor class TodoBucket() {
    var usersData = Map.empty<Principal, Model.UserTodoData.userTodosData>();

    //
    // USER DATA
    //

    // this function retrieve all data relatives to one specific users, and all items the user has created.
    // if some todos has been shared with the user, the response will need subsequent query call to retrieve the shared items inside their owner Model.UserTodoData.userTodosData
    public query ({ caller }) func getUserData(user: Principal) : async Result.Result<Model.UserTodoData.sharableUserData, Text> {
        if ( not Helpers.CheckAccess.principalIsTodoIndexCanister(caller) ) { return #err("cannot be called but by the index canister"); };

        let ?data = Map.get(usersData, Principal.compare, user) else return #err("No data for user");
        
        let sharedWithUser =    Iter.toArray( 
                                    Iter.flatMap( Map.entries(data.todosSharedWithUser), func ((principal, inner)) {
                                        Iter.map( Map.entries(inner), func ((todoId, permission)) : (Principal, Nat, Model.Todo.Permission) {
                                            (principal, todoId, permission)
                                        })
                                    })
                                );

        let resp = {
            todos               = Iter.toArray( Map.values(data.todos) );
            todosSharedWithUser = sharedWithUser;
        };

        #ok(resp)
    };

    public shared ({ caller }) func createUserData(user: Principal) : async Result.Result<(), Text> {
        if ( not Helpers.CheckAccess.principalIsTodoIndexCanister(caller) ) { return #err("cannot be called but by the index canister"); };

        let data = {
            todos                   = Map.empty<Nat, Model.Todo.Todo>();
            todosSharedWithUser     = Map.empty<Principal, Map.Map<Nat, Model.Todo.Permission>>();
            todosSharedWithOthers   = Map.empty<Principal, Map.Map<Nat, Model.Todo.Permission>>();

            todoLists                   = Map.empty<Nat, Model.TodoList.TodoList>();
            todoListsSharedWithUser     = Map.empty<Principal, Map.Map<Nat, Model.TodoList.TodoList>>();
            todoListsSharedWithOthers   = Map.empty<Principal, Map.Map<Nat, Model.TodoList.TodoList>>();
        };

        Map.add(usersData, Principal.compare, user, data);
        
        #ok
    };

    //
    // TODOS
    //

    public query ({ caller }) func getUserTodoPermission(user: Principal, todoId: Nat) : async Result.Result<Model.Todo.Permission, Text> {
        if ( not Helpers.CheckAccess.principalIsTodoIndexCanister(caller) ) { return #err("cannot be called but by the index canister"); };

        let ?data = Map.get(usersData, Principal.compare, user) else return #err("No data for user");
        
        switch ( Map.get(data.todos, Nat.compare, todoId) ) {
            case null { // in this case, it's still possible that the todo has been shared with the user
                for ( map in Map.values(data.todosSharedWithUser) ) {
                    switch ( Map.get(map, Nat.compare, todoId) ) {
                        case null ();
                        case (?permission) return #ok(permission);
                    }
                };

                #err("")
            };
            case (?todo) #ok(todo.permission);
        }
    };

    public shared ({ caller }) func createTodo(user: Principal, todo: Model.Todo.Todo) : async Result.Result<(), Text> {
        if ( not Helpers.CheckAccess.principalIsTodoIndexCanister(caller) ) { return #err("cannot be called but by the index canister"); };

        let ?data = Map.get(usersData, Principal.compare, user) else return #err("No data for user");

        Map.add(data.todos, Nat.compare, todo.id, todo);
        
        #ok
    };

    public shared ({ caller }) func updateTodo(user: Principal, todo: Model.Todo.Todo) : async Result.Result<(), Text> {
        if ( not Helpers.CheckAccess.principalIsTodoIndexCanister(caller) ) { return #err("cannot be called but by the index canister"); };

        let ?data = Map.get(usersData, Principal.compare, user) else return #err("No data for user");

        Map.add(data.todos, Nat.compare, todo.id, todo);
        
        #ok
    };

    public shared ({ caller }) func deleteTodo(user: Principal, todoId: Nat) : async Result.Result<(), Text> {
        if ( not Helpers.CheckAccess.principalIsTodoIndexCanister(caller) ) { return #err("cannot be called but by the index canister"); };

        let ?data = Map.get(usersData, Principal.compare, user) else return #err("No data for user");

        Map.remove(data.todos, Nat.compare, todoId);
        
        #ok
    };

    //
    // TODO LISTS
    //

    // WIP: do everything for lists
};