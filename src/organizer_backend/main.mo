import Text "mo:base/Text";
import Map "mo:map/Map";
import { phash; thash } "mo:map/Map";
import Result "mo:base/Result";

persistent actor {
    type Todo = {
        uuid: Text;
        resume: Text;
        description: Text;
        scheduledDate: Text;
        priority: Priority;
    };

    type Priority = {
        #high;
        #medium;
        #low;
    };

    // principal => todo_uuid => todo
    stable var todos = Map.new<Principal, Map.Map<Text, Todo>>();

    public shared ({ caller }) func addTodo(todo: Todo) : async Result.Result<(), Text> {
        switch (Map.get(todos, phash, caller)) {
            case null {
                let new_user_map = Map.new<Text, Todo>();
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
                    case (?_) #err("Todo already exists");
                };
            };
        };
    };

    public shared ({ caller }) func removeTodo(uuid: Text) : async () {
        switch (Map.get(todos, phash, caller)) {
            case null ();
            case (?user_todos_map) {
                Map.delete(user_todos_map, thash, uuid);
                // Map.set(todos, phash, caller, user_todos_map);
            };
        };
    };

    public query ({ caller }) func getTodos() : async ([Todo]) {
        switch (Map.get(todos, phash, caller)) {
            case null [];
            case (?user_todos_map) {
                Map.toArrayMap(user_todos_map, func(_ : Text, value: Todo) : ?Todo {
                    ?value
                })
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
}
