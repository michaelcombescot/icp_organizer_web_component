import Identifier "../../../shared/identifiers";
import Map "mo:core/Map";
import Time "mo:core/Time";
import Principal "mo:core/Principal";

module {
    public type Group = {
        identifier: Identifier.Identifier;
        name: Text;
        todos: Map.Map<Identifier.Identifier, ()>;
        todoLists: Map.Map<Identifier.Identifier, ()>;
        users: Map.Map<Principal, UserGroupPermission>;
        kind: Kind;
        createdAt: Time.Time;
        updatedAt: Time.Time;
        createdBy: Principal;
    };

    public type Kind = {
        #personnal;
        #collective;
    };

    public type UserGroupPermission = {
        // can do everything AND remove admins
        #owner;
        // can do everything related to the group, exept remove other admins
        #admin;
        // create todo/todolist, invite people
        #user;
        // can only read todos, cannot edit anything
        #visitor;
        //cannot do anything (user WAS in the group but was removed)
        #archived;
    };

    public func createGroup ({ name: Text; createdBy: Principal; identifier: Identifier.Identifier; kind: Kind }) : Group {
        {
            identifier = identifier;
            name = name;
            todos = Map.empty<Identifier.Identifier, ()>();
            todoLists = Map.empty<Identifier.Identifier, ()>();
            users = Map.singleton<Principal, UserGroupPermission>(createdBy, #owner);
            kind = kind;
            createdAt = Time.now();
            updatedAt = Time.now();
            createdBy = createdBy;
        }
    };

    //
    // API
    //

    public type CreateGroupParams = {
        name: Text;
        kind: Kind;
    };
};