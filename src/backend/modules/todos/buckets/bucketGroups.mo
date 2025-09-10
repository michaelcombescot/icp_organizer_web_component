import Map "mo:core/Map";
import Nat "mo:core/Nat";
import Array "mo:core/Array";
import Principal "mo:core/Principal";
import Group "../models/group";
import Result "mo:base/Result";
import Accesses "accesses";
import Todo "../models/todo";
import TodoList "../models/todoList";

persistent actor class BucketGroups() {
    var storeGroupsData = Map.empty<Nat, Group.GroupData>();

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

        Map.add(storeGroupsData, Nat.compare, groupId, groupData);
        Map.add(groupData.users, Principal.compare, adminPrincipal, #admin);
        
        #ok
    };

    public query ({ caller }) func getGroupsData(groupIds: [Nat]) : async Result.Result<[(Nat, Group.GroupDataSharable)], [Text]> {
        if ( not Accesses.principalIsTodoIndexCanister(caller) ) { return #err(["can only be called by the index canister"]); };

        let response: [(Nat, Group.GroupDataSharable)] = Array.filterMap(groupIds, func (groupId: Nat) : ?(Nat, Group.GroupDataSharable) {
            let ?groupData = Map.get(storeGroupsData, Nat.compare, groupId) else return null;

            let ?permission = Map.get(groupData.users, Principal.compare, caller) else return null;

            ?(
                groupId,
                {
                    id          = groupId;
                    name        = groupData.name;
                    todos       = Array.fromIter( Map.entries(groupData.todos) );
                    todoLists   = Array.fromIter( Map.entries(groupData.todoLists) );
                    permission  = permission;
                }
            )
        });

        #ok(response)
    };

}