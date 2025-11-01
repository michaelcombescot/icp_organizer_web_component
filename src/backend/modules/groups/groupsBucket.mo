import Map "mo:core/Map";
import Result "mo:core/Result";
import Principal "mo:core/Principal";
import Nat "mo:core/Nat";
import Text "mo:core/Text";
import Time "mo:base/Time";
import Group "groupModel";

shared ({ caller = owner }) persistent actor class GroupsBucket(indexPrincipal: Principal) = this {
    let index = indexPrincipal;
    
    let storeGroups = Map.empty<Text, Group.Group>();

    //
    // API
    //

    public shared ({ caller }) func createGroup(group: Group.CreateGroupParam) : async Result.Result<(Text, Nat), [Text]> {
        if ( caller != index ) { return #err(["can only be called by the index canister"]); };
    
        let id  = Principal.toText(Principal.fromActor(this)) # "_" # Nat.toText(Map.size(storeGroups));
        let now = Time.now();

        Map.add(storeGroups, Text.compare, id, {
            id = id;
            name = group.name;
            todos = Map.empty<Text, ()>();
            todoLists = Map.empty<Text, ()>();
            users = Map.empty<Principal, ()>();
            createdAt = now;
            updatedAt = now;
        });
    
        #ok(id, Map.size(storeGroups));
    };

    public query func isUserInGroup(groupId: Text, userPrincipal: Principal ) : async Bool {
        let ?group = Map.get(storeGroups, Text.compare, groupId) else return false;

        let ?_ = Map.get(group.users, Principal.compare, userPrincipal) else return false;
        return true;
    };
}