import Todo "../models/todoModel";
import Result "mo:core/Result";
import Map "mo:core/Map";
import Principal "mo:core/Principal";
import Text "mo:core/Text";
import Nat "mo:core/Nat";
import Array "mo:core/Array";
import Nat64 "mo:core/Nat64";
import Time "mo:core/Time";
import Identifiers "../../shared/identifiers";
import Interfaces "../../shared/interfaces";

shared ({ caller = owner }) persistent actor class TodosTodosBucket() = this {
    let thisPrincipalText = Principal.toText(Principal.fromActor(this));
    let coordinator = actor (Principal.toText(owner)) : Interfaces.Coordinator;

    ////////////
    // CONFIG //
    ////////////

    let CONFIG_INTERVAL_FETCH_INDEXES: Nat64    = 60_000_000_000;
    let CONFIG_MAX_NUMBER_ENTRIES: Nat          = 1_000_000;

    ////////////
    // ERRORS //
    ////////////

    let ERR_CAN_ONLY_BE_CALLED_BY_INDEX = "ERR_CAN_ONLY_BE_CALLED_BY_INDEX";

    ////////////
    // STORES //
    ////////////

    transient var storeIndexes        = Map.empty<Principal, ()>();

    let storeTodos          = Map.empty<Nat, Todo.Todo>();

    ////////////
    // SYSTEM //
    ////////////

    system func timer(setGlobalTimer : (Nat64) -> ()) : async () {
        storeIndexes := Map.fromIter(Array.map(await coordinator.handlerGetIndexes(), func(x) = (x, ())).values(), Principal.compare);
        setGlobalTimer(Nat64.fromIntWrap(Time.now()) + CONFIG_INTERVAL_FETCH_INDEXES);
    };

    /////////
    // API //
    /////////

    // create a new todo
    public shared ({ caller }) func handlerCreateTodo({ initialCaller: Principal; todo: Todo.Todo }) : async Result.Result<{ identifier: Identifiers.WithID; isFull: Bool }, [Text]> {
        let ?_ = Map.get(storeIndexes, Principal.compare, caller) else return #err([ERR_CAN_ONLY_BE_CALLED_BY_INDEX]);

        // validate todo data
        switch ( Todo.validateTodo(todo) ) {
            case (#ok(_)) ();
            case (#err(e)) return #err(e);
        };

        let identifier = { id = Map.size(storeTodos); bucket = thisPrincipalText };

        Map.add(storeTodos, Nat.compare, identifier.id, { todo with identifier = identifier; createdBy = initialCaller; createdAt = Time.now(); });

        #ok({ identifier = identifier; isFull = identifier.id > CONFIG_MAX_NUMBER_ENTRIES })
    };

    public shared ({ caller }) func getTodos(ids: [Nat]) : async Result.Result<[Todo.Todo], Text> {
       let ?_ = Map.get(storeIndexes, Principal.compare, caller) else return #err(ERR_CAN_ONLY_BE_CALLED_BY_INDEX);

       let todos = Array.filterMap( ids, func(id) = Map.get(storeTodos, Nat.compare, id) );

       #ok(todos)
    };

    public shared ({ caller }) func updateTodo(todo: Todo.Todo) : async Result.Result<(), [Text]> {
        let ?_ = Map.get(storeIndexes, Principal.compare, caller) else return #err([ERR_CAN_ONLY_BE_CALLED_BY_INDEX]);

        switch ( Todo.validateTodo(todo) ) {
            case (#ok(_)) ();
            case (#err(e)) return #err(e);
        };

        let _ = Map.swap(storeTodos, Nat.compare, todo.identifier.id, todo) else return #err(["No todo found"]);

        #ok
    };

    public shared ({ caller }) func removeTodo(id: Nat) : async Result.Result<(), Text> {
        let ?_ = Map.get(storeIndexes, Principal.compare, caller) else return #err(ERR_CAN_ONLY_BE_CALLED_BY_INDEX);

        Map.remove(storeTodos, Nat.compare, id);

        #ok
    };
}