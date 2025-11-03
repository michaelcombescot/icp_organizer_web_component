import Map "mo:core/Map";
import Result "mo:core/Result";
import Principal "mo:core/Principal";
import Nat "mo:core/Nat";
import Text "mo:core/Text";
import Iter "mo:core/Iter";
import Time "mo:base/Time";
import Group "groupModel";
import Types "../../shared/types";

shared ({ caller = owner }) persistent actor class GroupsBucket(indexPrincipal: Principal) = this {
    let thisPrincipalText = Principal.toText(Principal.fromActor(this));
    let index = indexPrincipal;
    
    let storeGroups = Map.empty<Nat, Group.Group>();

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
        id: Types.Identifiers;
        name: Text;
        todos: [Types.Identifiers];
        todoLists: [Types.Identifiers];
    };

    public shared ({ caller }) func getGroupData(id: Nat) : async Result.Result<GetGroupResponse, [Text]> {
        let ?group = Map.get(storeGroups, Nat.compare, id) else return #err([ERR_GROUP_NOT_FOUND]);

        let ?_ = Map.get(group.users, Principal.compare, caller) else return #err([ERR_USER_NOT_IN_GROUP]);

        #ok({
            id = group.identifiers;
            name = group.name;
            todos = Iter.toArray(Map.keys(group.todos));
            todoLists = Iter.toArray(Map.keys(group.todoLists));
        });
    };

    // create
    public shared ({ caller }) func createGroup({userPrincipal: Principal; group: Group.CreateGroupParam}) : async Result.Result<(Types.Identifiers, Nat), [Text]> {
        if ( caller != index ) { return #err(["can only be called by the index canister"]); };
    
        let now = Time.now();
        let identifiers = { bucket = thisPrincipalText; id = Map.size(storeGroups) };

        Map.add(storeGroups, Nat.compare, identifiers.id, {
            identifiers = identifiers;
            name = group.name;
            todos = Map.empty<Types.Identifiers, ()>();
            todoLists = Map.empty<Types.Identifiers, ()>();
            users = Map.fromIter<Principal, Group.UserGroupPermission>([(userPrincipal, #admin)].values(), Principal.compare);
            createdAt = now;
            updatedAt = now;
            createdBy = userPrincipal;
        });
    
        #ok(identifiers, Map.size(storeGroups));
    };

    // edit
    type EditGroupParam = {
        id: Nat;
        name: Text;
    };

    public shared ({ caller }) func editGroup({ groupData: EditGroupParam}) : async Result.Result<(), [Text]> {
        let ?group = Map.get(storeGroups, Nat.compare, groupData.id) else return #err([ERR_GROUP_NOT_FOUND]);
        
        let ?userPermission = Map.get(group.users, Principal.compare, caller) else return #err([ERR_USER_NOT_IN_GROUP]);

        if ( userPermission != #admin ) { return #err([ERR_USER_MUST_BE_ADMIN]); };

        ignore Map.replace(storeGroups, Nat.compare, groupData.id, { group with groupData; } );

        #ok
    };

    // delete
    public shared ({ caller }) func deleteGroup({ groupId: Nat}) : async Result.Result<(), [Text]> {
        let ?group = Map.get(storeGroups, Nat.compare, groupId) else return #err([ERR_GROUP_NOT_FOUND]);

        let ?userPermission = Map.get(group.users, Principal.compare, caller) else return #err([ERR_USER_NOT_IN_GROUP]);

        if ( userPermission != #admin ) { return #err([ERR_USER_MUST_BE_ADMIN]); };

        Map.remove(storeGroups, Nat.compare, groupId);

        #ok();
    };

    // add todo
    public shared ({ caller }) func addTodoToGroup({ groupId: Nat; todoId: Types.Identifiers;}) : async Result.Result<(), [Text]> {
        let ?group = Map.get(storeGroups, Nat.compare, groupId) else return #err([ERR_GROUP_NOT_FOUND]);

        let ?userPermission = Map.get(group.users, Principal.compare, caller) else return #err([ERR_USER_NOT_IN_GROUP]);

        if ( userPermission == #admin or userPermission == #user ) { return #err([ERR_USER_MUST_BE_ADMIN_OR_USER]); };

        Map.add(group.todos, Nat.compare, todoId, ());

        #ok
    };
}