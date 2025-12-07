import Identifier "../../../shared/identifiers";
import Map "mo:core/Map";
import Todo "todosTodo";
import TodoList "todosTodoList";
import Time "mo:core/Time";

module {
    public type Group = {
        identifier: Identifier.Identifier;
        name: Text;
        todos: Map.Map<Nat, Todo.Todo>;
        todoLists: Map.Map<Nat, TodoList.TodoList>;
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

    /// API ///

    

    //
    // API
    //

    public type CreateGroupParam = {
        name: Text;
    };
};