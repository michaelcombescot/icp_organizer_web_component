import Map "mo:core/Map";
import Todo "todo";
import TodoList "todoList";

module {
    public type UserData = {
        todoLists:  Map.Map<Nat, TodoList.TodoList>;
        todos:      Map.Map<Nat, Todo.Todo>;
    };

    public type UserDataSharable = {
        todoLists:  [(Nat, TodoList.TodoList)];
        todos:      [(Nat, Todo.Todo)];
    };

    public type GetUserDataResponse = {
        todoLists:  [(Nat, TodoList.TodoList)];
        todos:      [(Nat, Todo.Todo)];
    }
}