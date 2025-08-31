import Text "mo:base/Text";
import Time "mo:base/Time";
import Result "mo:base/Result";
import Option "mo:base/Option";
import Map "mo:core/Map";
import List "mo:core/List";

module Todo {
    //
    // DECLARATIONS
    //

    public type Todo = {
        id: Nat;
        resume: Text;
        description: ?Text;
        scheduledDate: ?Time.Time;
        priority: TodoPriority;
        status: TodoStatus;
        createdAt: Time.Time;
        todoListId: ?Nat;
        permission: Permission;
    };

    public func validateTodo(todo: Todo) : Result.Result<(), Text> {
        if ( todo.createdAt == 0 )  { return #err("todo.createdAt cannot be 0") };
        if ( todo.resume.size() == 0 or todo.resume.size() > 100 )  { return #err("todo.resume cannot be empty and must be less than 101 characters") };
        if ( Option.get(todo.description, "").size() > 50000 )  { return #err("todo.description cannot larger than 50000 characters") };

        #ok
    };

    type TodoPriority = {
        #high;
        #medium;
        #low;
    };

    type TodoStatus = {
        #pending;
        #done;
    };

    public type Permission = {
        #owned;
        #read;
        #write;
    };

    //
    // RESPONSES
    //

    public type TodoResponse = Todo and {
        todoList: ?TodoList.TodoList;
    };
};

module TodoList {
    public type TodoList = {
        id: Nat;
        name: Text;
        color: Text;
        todos: List.List<Nat>;
    };

    public type TodoListPermission = {
        #owner;
        #read;
        #write;
    };

    public func validateTodoList(todoList: TodoList) : Result.Result<(), Text> {
        if ( todoList.name.size() == 0 or todoList.name.size() > 100 )  { return #err("todoList.name cannot be empty and must be less than 101 characters") };
        if ( todoList.color.size() > 8 )  { return #err("todoList.color cannot be empty and must be less than 9 characters") };
        #ok
    };
};

module User {
    public type UserData = {
        todos: Map.Map<Nat, Todo.Todo>;
        todosSharedWithUser: Map.Map<Principal, Map.Map<Nat, Todo.Permission>>; // todos shared with the user and the associated permission
        todosSharedWithOthers: Map.Map<Principal, Map.Map<Nat, Todo.Permission>>; // todos that the user has shared, used to find which association to delete if one todo is deleted
        
        todoLists: Map.Map<Nat, TodoList.TodoList>;
        todoListsSharedWithUser: Map.Map<Principal, Map.Map<Nat, TodoList.TodoListPermission>>;
        todoListsSharedWithOthers: Map.Map<Principal, Map.Map<Nat, TodoList.TodoListPermission>>;
    };

    public type SharableTodo = {
        principal: Principal;
        todosData: [(Nat, Todo.Permission)];
    };

    public type SharableTodoList = {
        principal: Principal;
        todoListsData: [(Nat, TodoList.TodoListPermission)];
    };

    public type SharableUserData = {
        todos: [Todo.Todo];
        todosSharedWithUser: [SharableTodo];

        todoLists: [TodoList.TodoList];
        todoListsSharedWithUser: [SharableTodoList];
    };
}