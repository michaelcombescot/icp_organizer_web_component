import Time "mo:core/Time";
import Map "mo:core/Map";

module {
    public type Group = {
        id: Text;
        name: Text;
        todos: Map.Map<Text, ()>;
        todoLists: Map.Map<Text, ()>;
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
}