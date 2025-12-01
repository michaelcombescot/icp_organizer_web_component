import Time "mo:core/Time";
import Map "mo:core/Map";
import Result "mo:core/Result";
import List "mo:core/List";
import Option "mo:core/Option";
import Identifier "../../shared/identifiers";

module {
    public module Group {
        public type Memory = {
            identifier: Identifier.Identifier;
            name: Text;
            todos: Map.Map<Nat, Todo.Todo>;
            todoLists: Map.Map<Nat, TodoList.TodoList>;
            users: Map.Map<Principal, UserGroupPermission>;
            kind: GroupKind;
            createdAt: Time.Time;
            updatedAt: Time.Time;
            createdBy: Principal;
        };

        public type GroupKind = {
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

    public module Todo {
        public type Todo = {
            id: Nat;
            resume: Text;
            description: ?Text;
            scheduledDate: ?Time.Time;
            priority: TodoPriority;
            status: TodoStatus;
            createdAt: Time.Time;
            createdBy: Principal;
            owner: Principal;

        };

        public type TodoPriority    = { #high; #medium; #low; };
        public type TodoStatus      = { #pending; #done; };

        public func validateTodo(todo: Todo) : Result.Result<(), [Text]> {
            let errors = List.empty<Text>();

            if ( todo.resume.size() == 0 or todo.resume.size() > 100 )  { List.add(errors, "todo.resume cannot be empty and must be less than 101 characters") };
            if ( Option.get(todo.description, "").size() > 5000 )  { List.add(errors, "todo.description cannot be empty and must be less than 5000 characters") };

            if ( List.size(errors) == 0 ) { #ok } else { #err( List.toArray(errors) ) }
        };
    };

    public module TodoList {
        public type TodoList = {
            id: Nat;
            name: Text;
            color: Text;
            owner: Principal;
            createdAt: Time.Time;
            createdBy: Principal;
        };
    };
};

