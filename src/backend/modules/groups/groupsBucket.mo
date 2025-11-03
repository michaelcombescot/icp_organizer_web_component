import Map "mo:core/Map";
import Result "mo:core/Result";
import Principal "mo:core/Principal";
import Nat "mo:core/Nat";
import Text "mo:core/Text";
import Iter "mo:core/Iter";
import Time "mo:base/Time";
import Group "groupModel";

shared ({ caller = owner }) persistent actor class GroupsBucket(indexPrincipal: Principal) = this {
    let thisPrincipalText = Principal.toText(Principal.fromActor(this));
    let index = indexPrincipal;
    
    let storeGroups = Map.empty<Text, Group.Group>();

    //
    // ERRORS
    //

    transient let ERR_GROUP_NOT_FOUND               = "ERR_GROUP_NOT_FOUND";
    transient let ERR_USER_NOT_IN_GROUP             = "ERR_USER_NOT_IN_GROUP";
    transient let ERR_USER_MUST_BE_ADMIN            = "ERR_USER_MUST_BE_ADMIN";
    transient let ERR_USER_MUST_BE_ADMIN_OR_USER    = "ERR_USER_MUST_BE_ADMIN_OR_USER";

    //
    // API
    //

    // get group data
    type GetGroupResponse = {
        id: Text;
        name: Text;
        todos: [Text];
        todoLists: [Text];
    };

    public shared ({ caller }) func getGroupData(id: Text) : async Result.Result<GetGroupResponse, [Text]> {
        let ?group = Map.get(storeGroups, Text.compare, id) else return #err([ERR_GROUP_NOT_FOUND]);

        let ?_ = Map.get(group.users, Principal.compare, caller) else return #err([ERR_USER_NOT_IN_GROUP]);

        #ok({
            id = group.id;
            name = group.name;
            todos = Iter.toArray(Map.keys(group.todos));
            todoLists = Iter.toArray(Map.keys(group.todoLists));
        });
    };

    // create
    public shared ({ caller }) func createGroup({userPrincipal: Principal; group: Group.CreateGroupParam}) : async Result.Result<(Text, Nat), [Text]> {
        if ( caller != index ) { return #err(["can only be called by the index canister"]); };
    
        let id  = thisPrincipalText # "_" # Nat.toText(Map.size(storeGroups));
        let now = Time.now();

        Map.add(storeGroups, Text.compare, id, {
            id = id;
            name = group.name;
            todos = Map.empty<Text, ()>();
            todoLists = Map.empty<Text, ()>();
            users = Map.fromIter<Principal, Group.UserGroupPermission>([(userPrincipal, #admin)].values(), Principal.compare);
            createdAt = now;
            updatedAt = now;
            createdBy = userPrincipal;
        });
    
        #ok(id, Map.size(storeGroups));
    };

    // edit
    type EditGroupParam = {
        id: Text;
        name: Text;
    };

    public shared ({ caller }) func editGroup({ groupData: EditGroupParam}) : async Result.Result<(), [Text]> {
        let ?group = Map.get(storeGroups, Text.compare, groupData.id) else return #err([ERR_GROUP_NOT_FOUND]);
        
        let ?userPermission = Map.get(group.users, Principal.compare, caller) else return #err([ERR_USER_NOT_IN_GROUP]);

        if ( userPermission != #admin ) { return #err([ERR_USER_MUST_BE_ADMIN]); };

        ignore Map.replace(storeGroups, Text.compare, groupData.id, { group with groupData; } );

        #ok
    };

    // delete
    public shared ({ caller }) func deleteGroup({ groupId: Text}) : async Result.Result<(), [Text]> {
        let ?group = Map.get(storeGroups, Text.compare, groupId) else return #err([ERR_GROUP_NOT_FOUND]);

        let ?userPermission = Map.get(group.users, Principal.compare, caller) else return #err([ERR_USER_NOT_IN_GROUP]);

        if ( userPermission != #admin ) { return #err([ERR_USER_MUST_BE_ADMIN]); };

        Map.remove(storeGroups, Text.compare, groupId);

        #ok();
    };

    // add todo
    public shared ({ caller }) func addTodoToGroup({ groupId: Text; todoId: Text;}) : async Result.Result<(), [Text]> {
        let ?group = Map.get(storeGroups, Text.compare, groupId) else return #err([ERR_GROUP_NOT_FOUND]);

        let ?userPermission = Map.get(group.users, Principal.compare, caller) else return #err([ERR_USER_NOT_IN_GROUP]);

        if ( userPermission == #admin or userPermission == #user ) { return #err([ERR_USER_MUST_BE_ADMIN_OR_USER]); };

        Map.add(group.todos, Text.compare, todoId, ());

        #ok
    };
}