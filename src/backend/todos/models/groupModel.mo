import Time "mo:core/Time";
import Map "mo:core/Map";

module Group {
    public type Group = {
        id: Nat;
        bucket: Principal;
        name: Text;
        todos: Map.Map<Nat, ()>;
        todoLists: Map.Map<Nat, ()>;
        users: Map.Map<Principal, UserGroupPermission>;
        createdAt: Time.Time;
        updatedAt: Time.Time;
        createdBy: Principal;
    };

    public type UserGroupPermission = {
        // can do everything related to the group
        #admin;
        // create todo/todolist, invite people
        #user;
        // can only read todos, cannot edit anything
        #visitor;
    };

    //
    // API
    //

    public type CreateGroupParam = {
        name: Text;
    };
};