import Text "mo:base/Text";
import Time "mo:base/Time";
import Result "mo:base/Result";
import Option "mo:base/Option";

module {
    // TODO
    public type Todo = {
        uuid: Text;
        resume: Text;
        description: ?Text;
        scheduledDate: ?Time.Time;
        priority: TodoPriority;
        status: TodoStatus;
        createdAt: Time.Time;
        todoListUUID: ?Text;
    };

    public func validateTodo(todo: Todo) : Result.Result<(), Text> {
        if ( todo.createdAt == 0 )  { return #err("todo.createdAt cannot be 0") };
        if ( Option.get(todo.todoListUUID, "").size() != 36 )  { return #err("todo.todoListUUID must be an uuid") };
        if ( todo.uuid.size() != 36 )  { return #err("todo.uuid must be an uuid") };
        if ( todo.resume.size() == 0 or todo.resume.size() > 100 )  { return #err("todo.resume cannot be empty and must be less than 101 characters") };
        if ( Option.get(todo.description, "").size() > 3000 )  { return #err("todo.description cannot larger than 3001 characters") };

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

    // TODO LIST
    public type TodoList = {
        uuid: Text;
        name: Text;
        color: Text;
    };

    public func validateTodoList(todoList: TodoList) : Result.Result<(), Text> {
        if ( todoList.name.size() == 0 or todoList.name.size() > 100 )  { return #err("todoList.name cannot be empty and must be less than 101 characters") };
        if ( todoList.uuid.size() != 36 )  { return #err("todoList.uuid must be an uuid") };
        if ( todoList.color.size() > 8 )  { return #err("todoList.color cannot be empty and must be less than 9 characters") };
        #ok
    };
}