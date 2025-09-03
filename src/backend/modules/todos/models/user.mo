import Map "mo:core/Map";
import Todo "todo";
import TodoList "todoList";

module {
    public type UserData = {
        todoLists:  Map.Map<Nat, TodoList.TodoList>;
        todos:      Map.Map<Nat, Todo.Todo>;
        groups:     Map.Map<Nat, ()>;
    };
}