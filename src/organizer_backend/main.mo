import Text "mo:base/Text";
import Map "mo:map/Map";
import { phash; thash } "mo:map/Map";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Principal "mo:base/Principal";

persistent actor {
    type Todo = {
        uuid: Text;
        resume: Text;
        description: Text;
        scheduledDate: Time.Time;
        priority: TodoPriority;
        status: TodoStatus;
        createdAt: Time.Time;
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

    // principal => todo_uuid => todo
    stable var todos = Map.new<Principal, Map.Map<Text, Todo>>();

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
                    case (?_) #err("Todo already exists with this uuid");
                };
            };
        };
    };

    public shared ({ caller }) func updateTodo(todo: Todo) : async Result.Result<(), Text> {
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

    public query ({caller}) func whoami() : async Text {
        Principal.toText(caller)
    };
}
