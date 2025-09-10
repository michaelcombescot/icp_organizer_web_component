import Map "mo:core/Map";
import Todo "todo";
import TodoList "todoList";
import Group "group";

module {
    public type UserData = {
        todoLists:  Map.Map<Nat, TodoList.TodoList>;
        todos:      Map.Map<Nat, Todo.Todo>;
        groups:     Map.Map<Nat, ()>;
    };

    public type UserDataSharable = {
        todoLists:  [(Nat, TodoList.TodoList)];
        todos:      [(Nat, Todo.Todo)];
        groups:     [(Nat, ())];
    };

    public type GetUserDataResponse = {
        todoLists:  [(Nat, TodoList.TodoList)];
        todos:      [(Nat, Todo.Todo)];
        groups:     [(Nat, Group.GroupDataSharable)];
    }
}