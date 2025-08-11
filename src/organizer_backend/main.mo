import Text "mo:base/Text";
import Map "mo:map/Map";
import { phash; thash } "mo:map/Map";
import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Option "mo:base/Option";
import Todo "./todo/todo";

persistent actor {
    /////
    // memory declarations
    /////

    var todos       = Map.new<Principal, Map.Map<Text, Todo.Todo>>();
    var todoLists   = Map.new<Principal, Map.Map<Text, Todo.TodoList>>();

    /////
    // TODO homepage interface
    /////

    public query ({ caller }) func getTodos() : async ([Todo.Todo]) {
        if ( Principal.isAnonymous(caller) ) { return []; };

        let ?callerTodos = Map.get(todos, phash, caller) else return [];
        Map.toArrayMap(callerTodos, func(_ : Text, value: Todo.Todo) : ?Todo.Todo { ?value })
    };

    public shared ({ caller }) func addTodo(todo: Todo.Todo) : async Result.Result<(), Text> {
        if ( Principal.isAnonymous(caller) ) { return #err("Not logged in"); };

        switch (Todo.validateTodo(todo)) { case (#ok()) (); case (#err(e)) return #err("Invalid todo: " # e); };

        let callerTodosMap =    switch ( Map.get(todos, phash, caller) ) {
                                    case null Map.new<Text, Todo.Todo>();
                                    case ( ?callerTodosMap ) callerTodosMap;
                                };

        switch ( Map.get(callerTodosMap, thash, todo.uuid) ) {
            case null {
                Map.set(callerTodosMap, thash, todo.uuid, todo);
                Map.set(todos, phash, caller, callerTodosMap);
            };
            case (?_) return #err("Todo already exists with this uuid");
        };

        #ok
    };

    public shared ({ caller }) func updateTodo(todo: Todo.Todo) : async Result.Result<(), Text> {
        if ( Principal.isAnonymous(caller) ) { return #err("Not logged in"); };
        
        switch (Todo.validateTodo(todo)) { case (#ok()) (); case (#err(e)) return #err("Invalid todo: " # e); };

        let ?callerTodos = Map.get(todos, phash, caller) else return #err("caller todos not found"); 
        let ?_ = Map.get(callerTodos, thash, todo.uuid) else return #err("todo not found");
        #ok(Map.set(callerTodos, thash, todo.uuid, todo))
    };

    public shared ({ caller }) func removeTodo(uuid: Text) : async Result.Result<(), Text> {
        if ( Principal.isAnonymous(caller) ) { return #err("Not logged in"); };

        let ?callerTodos = Map.get(todos, phash, caller) else return #err("caller todos not found");
        let ?_ = Map.get(callerTodos, thash, uuid) else return #err("todo not found");
        #ok(Map.delete(callerTodos, thash, uuid))
    };

    public query ({ caller }) func sizeTodo() : async Result.Result<Nat, Text> {
        if ( Principal.isAnonymous(caller) ) { return #err("Not logged in"); };

        let ?callerTodos = Map.get(todos, phash, caller) else return #ok(0);
        #ok(Map.size(callerTodos))
    };

    /////
    // TODO LIST INTERFACE
    /////

    public query ({ caller }) func getTodoLists() : async Result.Result<[Todo.TodoList], Text> {
        if ( Principal.isAnonymous(caller) ) { return #err("Not logged in"); };

        let ?callerTodoLists = Map.get(todoLists, phash, caller) else return #ok([]);
        #ok(Map.toArrayMap(callerTodoLists, func(_ : Text, value: Todo.TodoList) : ?Todo.TodoList { ?value }))
    };

    public shared ({ caller }) func addTodoList(todoList: Todo.TodoList) : async Result.Result<(), Text> {
        if ( Principal.isAnonymous(caller) ) { return #err("Not logged in"); };

        switch (Todo.validateTodoList(todoList)) { case (#ok()) (); case (#err(e)) return #err("Invalid todo list: " # e); };

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

    public shared ({ caller}) func updateTodoList(list: Todo.TodoList) : async Result.Result<(), Text> {
        if ( Principal.isAnonymous(caller) ) { return #err("Not logged in"); };

        switch (Todo.validateTodoList(list)) { case (#ok()) (); case (#err(e)) return #err("Invalid todo list: " # e); };

        let ?callerTodoLists = Map.get(todoLists, phash, caller) else return #err("Todo list not found");
        let ?todoList = Map.get(callerTodoLists, thash, list.uuid) else return #err("Todo list not found");
        #ok(Map.set(callerTodoLists, thash, todoList.uuid, list))
    };

    public shared ({ caller }) func removeTodoList(uuid: Text) : async Result.Result<(), Text> {
        if ( Principal.isAnonymous(caller) ) { return #err("Not logged in"); };

        let ?callerTodoLists = Map.get(todoLists, phash, caller) else return #err("Todo list not found");
        Map.delete(callerTodoLists, thash, uuid);

        let ?callerTodos = Map.get(todos, phash, caller) else return #err("caller todos not found");
        for ((todoUUID, todo) in Map.entries(callerTodos)) {
            if ( Option.get(todo.todoListUUID, "") == uuid ) { Map.delete(callerTodos, thash, todoUUID); };
        };

        #ok
    };

    /////
    // auth interface
    /////

    public query ({caller}) func whoami() : async Text {
        Principal.toText(caller)
    };
}

