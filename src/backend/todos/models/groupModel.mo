import Time "mo:core/Time";
import Map "mo:core/Map";
import Identifiers "../../shared/identifiers";

module {
    public type Group = {
        identifiers: Identifiers.WithID;
        name: Text;
        todos: Map.Map<Nat, TodoData>;
        todoLists: Map.Map<Nat, TodoListData>;
        users: Map.Map<Principal, UserGroupPermission>;
        createdAt: Time.Time;
        updatedAt: Time.Time;
        createdBy: Principal;
    };

    public type TodoData = { bucket: Text; };
    public type TodoListData = { bucket: Text; };

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