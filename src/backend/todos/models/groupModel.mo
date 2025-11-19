import Time "mo:core/Time";
import Map "mo:core/Map";
import Identifiers "../../shared/identifiers";

module {
    public type Group = {
        identifiers: Identifiers.WithID;
        name: Text;
        todos: Map.Map<Identifiers.WithID, ()>;
        todoLists: Map.Map<Identifiers.WithID, ()>;
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