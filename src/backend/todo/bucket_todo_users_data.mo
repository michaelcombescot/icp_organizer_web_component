import Map "mo:core/Map";
import Result "mo:core/Result";
import Principal "mo:core/Principal";
import Nat "mo:core/Nat";
import Iter "mo:core/Iter";
import Model "model";
import Helpers "helpers_todo";

persistent actor class TodoUserBucket() {
    var usersTodos              = Map.empty<Principal, Map.Map<Nat, Model.Todo.Permissions>>();
    var usersTodoLists          = Map.empty<Principal, Map.Map<Nat, Model.Todo.Permissions>>();

    //
    // QUERIES
    //

    public query ({ caller }) func getCallerTodosWithPermissions(user: Principal) : async Result.Result<[(Nat, Model.Todo.Permissions)], Text> {
        if ( not Helpers.CheckAccess.principalIsTodoIndexCanister(caller) ) { return #err("cannot be called but by the index canister"); };

        let ?permissions = Map.get(usersTodos, Principal.compare, user) else return #err("No permissions");

        #ok( Iter.toArray(Map.entries(permissions)) )
    };

    public query ({ caller }) func getCallerTodoPermission(user: Principal, todoId: Nat) : async Result.Result<Model.Todo.Permissions, Text> {
        if ( not Helpers.CheckAccess.principalIsTodoIndexCanister(caller) ) { return #err("cannot be called but by the index canister"); };

        let ?todos = Map.get(usersTodos, Principal.compare, user) else return #err("No user todo entry");
        let ?permission = Map.get(todos, Nat.compare, todoId) else return #err("No permission");

        #ok(permission)
    };

    //
    // UPDATE
    //

    public shared ({ caller }) func linkTodoToUser(todoId: Nat, caller: Principal, permission: Model.Todo.Permissions) : async Result.Result<(), Text> {
        if ( not Helpers.CheckAccess.principalIsTodoIndexCanister(caller) ) { return #err("cannot be called but by the index canister"); };

        // add todo to user
        switch ( Map.get(usersTodos, Principal.compare, caller) ) {
            case null {
                var todos = Map.empty<Nat, Model.Todo.Permissions>();
                Map.add(todos, Nat.compare, todoId, permission);
                Map.add(usersTodos, Principal.compare, caller, todos);
            };
            case (?todos) {
                Map.add(todos, Nat.compare, todoId, permission);
            }
        };

        #ok
    };
};