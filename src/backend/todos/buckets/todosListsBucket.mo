// import Map "mo:core/Map";
// import Result "mo:core/Result";
// import Time "mo:core/Time";
// import Principal "mo:core/Principal";
// import Nat "mo:core/Nat";
// import Text "mo:core/Text";
// import TodoList "todoListModel";

shared ({ caller = owner }) persistent actor class TodosListsBucket() = this {
//    let storeTodoLists = Map.empty<Text, TodoList.TodoList>();

//    //
//    // API
//    //

//    // public query func getTodoLists(ids: [Text]) : Result.Result<[TodoList.TodoList], Text> {
//    //    let todoLists = List.empty<TodoList.TodoList>();
//    //    for (id in ids) {
//    //       let ?todoList = Map.get(storeTodoLists, Text.compare, id) else return #err(["No todo list found"]);
//    //    } { List.add(todoLists, Map.get(storeTodoLists, Text.compare, i)) };
//    //    return #ok(List.toArray(todoLists));
//    // }

//    public shared ({ caller }) func createTodoList(userPrincipal: Principal, todoListData: TodoList.CreateTodoListData) : async Result.Result<(), [Text]> {
//       if ( caller != index ) { return #err(["can only be called by the index todo canister"]); };

//       switch ( TodoList.validateTodoList(todoListData) ) {
//          case (#ok(_)) ();
//          case (#err(e)) return #err(e);
//       };

//       let id = Principal.toText(Principal.fromActor(this)) # "_" # Nat.toText(Map.size(storeTodoLists));
//       Map.add(storeTodoLists, Text.compare, id, {
//                                                    id = id;
//                                                    name=todoListData.name;
//                                                    color=todoListData.color;
//                                                    todos = Map.empty<Text, ()>();
//                                                    owner=#user(userPrincipal);
//                                                    createdAt=Time.now()
//                                                 }
//       );

//       #ok
//     };

//     public shared ({ caller }) func updateTodoList(todoListData: TodoList.UpdateTodoListData) : async Result.Result<(), [Text]> {
//       let ?todoList = Map.get(storeTodoLists, Text.compare, todoListData.id) else return #err(["No todo list found"]);

//       if ( todoList.owner != #user(caller) ) { return #err(["can only be called by the owner of the todo list"]); };

//       switch ( TodoList.validateTodoList(todoListData) ) {
//          case (#ok(_)) ();
//          case (#err(e)) return #err(e);
//       };

//       ignore Map.replace(storeTodoLists, Text.compare, todoListData.id, { todoList with name = todoListData.name; color = todoListData.color; } );

//       #ok
//     };

//    // remove the list and all associated todos
//    public shared ({ caller }) func removeTodoList(id: Text) : async Result.Result<(), [Text]> {
//       let ?todoList = Map.get(storeTodoLists, Text.compare, id) else return #err(["No todo list found"]);

//       if ( todoList.owner != #user(caller) ) { return #err(["can only be called by the owner of the todo list"]); };

//       Map.remove(storeTodoLists, Text.compare, id);

//       #ok
//     };
}