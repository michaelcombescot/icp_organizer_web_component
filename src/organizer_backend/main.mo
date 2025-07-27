import Text "mo:base/Text";
import Map "mo:map/Map";
import { phash; thash } "mo:map/Map";
import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Todo "./todo/todo";

persistent actor {
    /////
    // memory declarations
    /////

    // Main memory for the todo module, format is Map<Principal, Map<todo_uuid, todo_data>>
    var todos = Map.new<Principal, Map.Map<Text, Todo.Todo>>();

    // memory for todo lists, format is Map<Principal, Map<todo_list_uuid, todo_list_data>>
    // todo_list_data.todos contains all the todo uuids linked to the list
    var todoLists = Map.new<Principal, Map.Map<Text, Todo.TodoList>>();

    /////
    // TODO homepage interface
    /////

    public query ({ caller }) func getTodos() : async ([Todo.Todo]) {
        switch (Map.get(todos, phash, caller)) {
            case null [];
            case (?user_todos_map) {
                Map.toArrayMap(user_todos_map, func(_ : Text, value: Todo.Todo) : ?Todo.Todo {
                    ?value
                })
            };
        };
    };

    public shared ({ caller }) func addTodo(todo: Todo.Todo) : async Result.Result<(), Text> {
        switch (Map.get(todos, phash, caller)) {
            case null {
                let new_user_map = Map.new<Text, Todo.Todo>();
                Map.set(new_user_map, thash, todo.uuid, todo);
                Map.set(todos, phash, caller, new_user_map);

                return #ok;
            };
            case (?user_todos_map) {
                switch (Map.get(user_todos_map, thash, todo.uuid)) {
                    case null {
                        Map.set(user_todos_map, thash, todo.uuid, todo);
                        #ok
                    };
                    case (?_) #err("Todo already exists with this uuid");
                };
            };
        };
    };

    public shared ({ caller }) func updateTodo(todo: Todo.Todo) : async Result.Result<(), Text> {
        switch (Map.get(todos, phash, caller)) {
            case null #err("Todo not found");
            case (?user_todos_map) {
                switch (Map.get(user_todos_map, thash, todo.uuid)) {
                    case null #err("Todo not found");
                    case (?_) {
                        Map.set(user_todos_map, thash, todo.uuid, todo);
                        #ok
                    };
                };
            };
        };
    };

    public shared ({ caller }) func removeTodo(uuid: Text) : async () {
        switch (Map.get(todos, phash, caller)) {
            case null ();
            case (?user_todos_map) {
                Map.delete(user_todos_map, thash, uuid);
            };
        };
    };

    public query ({ caller }) func sizeTodo() : async (Nat) {
        switch (Map.get(todos, phash, caller)) {
            case null 0;
            case (?user_todos_map) {
                Map.size(user_todos_map)
            };
        }
    };

    /////
    // TODO LIST INTERFACE
    /////

    public shared ({ caller }) func createTodoList(todoList: Todo.TodoList) : async Result.Result<(), Text> {
        switch (Map.get(todoLists, phash, caller)) {
            case null {
                let listMap = Map.new<Text, Todo.TodoList>();
                Map.set(listMap, thash, todoList.uuid, todoList);
                Map.set(todoLists, phash, caller, listMap);
                return #ok;
            };
            case (?todoLists) {
                switch (Map.get(todoLists, thash, todoList.uuid)) {
                    case null {
                        Map.set(todoLists, thash, todoList.uuid, todoList);
                        #ok
                    };
                    case (?_) #err("Todo list already exists with this uuid");
                }
            };
        };
    };

    /////
    // auth interface
    /////

    public query ({caller}) func whoami() : async Text {
        Principal.toText(caller)
    };
}

