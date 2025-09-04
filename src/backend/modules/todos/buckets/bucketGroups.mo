import Map "mo:core/Map";
import Nat "mo:core/Nat";
import Array "mo:core/Array";
import Principal "mo:core/Principal";
import Group "../models/group";
import Result "mo:base/Result";
import Accesses "accesses";
import Todo "../models/todo";
import TodoList "../models/todoList";

persistent actor class BucketGroups({ _cycles: Nat}) {
    var groupsData = Map.empty<Nat, Group.GroupData>();

    //
    // GROUP DATA
    //

    public query ({ caller }) func createGroupData({ adminPrincipal: Principal; groupName: Text; groupId: Nat}) : async Result.Result<(), [Text]> {
        if ( not Accesses.principalIsTodoIndexCanister(caller) ) { return #err(["can only be called by the index canister"]); };

        let groupData = {
            name      = groupName;
            todos     = Map.empty<Nat, Todo.Todo>();
            todoLists = Map.empty<Nat, TodoList.TodoList>();
            users     = Map.empty<Principal, Group.GroupPermission>();
        };

        switch ( Group.validateGroupData(groupName) ) {
            case (#ok) ();
            case (#err err) return #err(err);
        };

        Map.add(groupsData, Nat.compare, groupId, groupData);
        Map.add(groupData.users, Principal.compare, adminPrincipal, #admin);
        
        #ok
    };

    public query ({ caller }) func getGroupData(groupId: Nat) : async Result.Result<{name: Text;todos: [Todo.Todo]; todoLists: [TodoList.TodoList]}, [Text]> {
        if ( not Accesses.principalIsTodoIndexCanister(caller) ) { return #err(["can only be called by the index canister"]); };

        let ?groupData = Map.get(groupsData, Nat.compare, groupId) else return #err(["No group data"]);

        #ok(
            {
                name = groupData.name;
                todos = Array.fromIter( Map.values(groupData.todos) );
                todoLists = Array.fromIter( Map.values(groupData.todoLists) );
            }
        )
    };

}