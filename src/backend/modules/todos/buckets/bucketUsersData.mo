import Map "mo:core/Map";
import Result "mo:core/Result";
import Principal "mo:core/Principal";
import Nat "mo:core/Nat";
import Array "mo:core/Array";
import Debug "mo:core/Debug";
import Accesses "accesses";
import Todo "../models/todo";
import TodoList "../models/todoList";
import User "../models/user";

persistent actor class BucketUsersData() {
    var usersData = Map.empty<Principal, User.UserData>();

    //
    // USER DATA
    //

    public shared ({ caller }) func createUserData(userPrincipal: Principal) : async Result.Result<(), Text> {
        if ( not Accesses.principalIsTodoIndexCanister(caller) ) { return #err("can only be called by the index canister"); };

        let userData = {
            todos     = Map.empty<Nat, Todo.Todo>();
            todoLists = Map.empty<Nat, TodoList.TodoList>();
        };

        Map.add(usersData, Principal.compare, userPrincipal, userData);
        
        #ok
    };

    public query ({ caller }) func getUserData(userPrincipal: Principal) : async Result.Result<User.UserDataSharable, Text> {
        if ( not Accesses.principalIsTodoIndexCanister(caller) ) { return #err("can only be called by the index canister"); };

        let ?userData = Map.get(usersData, Principal.compare, userPrincipal) else return #err("No user data");

        #ok(
            {
                todos       = Array.fromIter( Map.entries(userData.todos) );
                todoLists   = Array.fromIter( Map.entries(userData.todoLists) );
            }
        )
    };

    //
    // TODO
    //

    public shared ({ caller }) func createTodo(userPrincipal: Principal, todo: Todo.Todo) : async Result.Result<(), [Text]> {
        if ( not Accesses.principalIsTodoIndexCanister(caller) ) { return #err(["can only be called by the index canister"]); };

        let ?userData = Map.get(usersData, Principal.compare, userPrincipal) else return #err(["No user data"]);

        Map.add(userData.todos, Nat.compare, todo.id, todo);

        #ok
    };

    public shared ({ caller }) func updateTodo(userPrincipal: Principal, todo: Todo.Todo) : async Result.Result<(), [Text]> {
        if ( not Accesses.principalIsTodoIndexCanister(caller) ) { return #err(["can only be called by the index canister"]); };

        let ?userData = Map.get(usersData, Principal.compare, userPrincipal) else return #err(["No user data"]);

        let _ = Map.swap(userData.todos, Nat.compare, todo.id, todo) else return #err(["No todo found"]);

        #ok
    };

    public shared ({ caller }) func removeTodo(userPrincipal: Principal, todoId: Nat) : async Result.Result<(), [Text]> {
        if ( not Accesses.principalIsTodoIndexCanister(caller) ) { return #err(["can only be called by the index canister"]); };

        let ?userData = Map.get(usersData, Principal.compare, userPrincipal) else return #err(["No user data"]);

        Map.remove(userData.todos, Nat.compare, todoId);

        #ok
    };


    //
    // TODOLIST
    //

    public shared ({ caller }) func createTodoList(userPrincipal: Principal, todoList: TodoList.TodoList) : async Result.Result<(), [Text]> {
        if ( not Accesses.principalIsTodoIndexCanister(caller) ) { return #err(["can only be called by the index canister"]); };

        let ?userData = Map.get(usersData, Principal.compare, userPrincipal) else return #err(["No user data"]);

        Map.add(userData.todoLists, Nat.compare, todoList.id, todoList);

        #ok
    };

    public shared ({ caller }) func updateTodoList(userPrincipal: Principal, todoList: TodoList.TodoList) : async Result.Result<(), [Text]> {
        if ( not Accesses.principalIsTodoIndexCanister(caller) ) { return #err(["can only be called by the index canister"]); };

        let ?userData = Map.get(usersData, Principal.compare, userPrincipal) else return #err(["No user data"]);

        let _ = Map.swap(userData.todoLists, Nat.compare, todoList.id, todoList) else return #err(["No todo list found"]);

        #ok
    };

    public shared ({ caller }) func removeTodoList(userPrincipal: Principal, todoListId: Nat) : async Result.Result<(), [Text]> {
        if ( not Accesses.principalIsTodoIndexCanister(caller) ) { return #err(["can only be called by the index canister"]); };

        let ?userData = Map.get(usersData, Principal.compare, userPrincipal) else return #err(["No user data"]);

        Map.remove(userData.todoLists, Nat.compare, todoListId);

        #ok
    };
};