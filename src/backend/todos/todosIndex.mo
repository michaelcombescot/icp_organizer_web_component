import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Text "mo:core/Text";
import Time "mo:core/Time";
import Map "mo:core/Map";
import Array "mo:core/Array";
import Nat64 "mo:core/Nat64";
import Runtime "mo:core/Runtime";
import Identifiers "../shared/identifiers";
import TodosTodosBucket "buckets/todosTodosBucket";
import TodosUsersDataBucket "buckets/todosUsersDataBucket";
import TodosGroupsBucket "buckets/todosGroupsBucket";
import TodosListsBucket "buckets/todosListsBucket";
import CanistersKinds "../ops/canistersKinds";
import Interfaces "../shared/interfaces";
import TodoModel "models/todoModel";
import TodoListModel "models/todoListModel";
import GroupModel "models/groupModel";
import UserDataModel "models/userDataModel";

shared ({ caller = owner }) persistent actor class TodosIndex() = this {
    var coordinator = actor(Principal.toText(owner)) : Interfaces.Coordinator;

    ////////////
    // CONFIG //
    ////////////

    let TIMER_INTERVAL_NS: Nat64 = 60_000_000_000;

    ////////////
    // ERRORS //
    ////////////

    transient let ERR_NOT_CONNECTED = "ERR_NOT_CONNECTED";

    ////////////
    // MEMORY //
    ////////////

    transient var memoryBucketsTodos = Map.empty<Principal, TodosTodosBucket.TodosTodosBucket>();
    transient var memoryBucketsUsersData = Map.empty<Principal, TodosUsersDataBucket.TodosUsersDataBucket>();
    transient var memoryBucketsGroups = Map.empty<Principal, TodosGroupsBucket.TodosGroupsBucket>();
    transient var memoryBucketsLists = Map.empty<Principal, TodosListsBucket.TodosListsBucket>();

    var currentTodosBucket = actor(Principal.toText(owner)) : TodosTodosBucket.TodosTodosBucket;
    var currentUsersDataBucket = actor(Principal.toText(owner)) : TodosUsersDataBucket.TodosUsersDataBucket;
    var currentGroupsBucket = actor(Principal.toText(owner)) : TodosGroupsBucket.TodosGroupsBucket;
    var currentListsBucket = actor(Principal.toText(owner)) : TodosListsBucket.TodosListsBucket;

    ////////////
    // SYSTEM //
    ////////////

    system func timer(setGlobalTimer : (Nat64) -> ()) : async () {
        for ( nature in CanistersKinds.bucketTodoKindArray.values() ) {
            let principals = await coordinator.handlerGetBuckets( { nature = #todos(nature) } );

            switch (nature) {
                case (#todosTodosBucket) {
                    let arrayEntries = Array.map(principals, func(principal) = (principal, actor(Principal.toText(principal)) : TodosTodosBucket.TodosTodosBucket));
                    memoryBucketsTodos := Map.fromIter<Principal, TodosTodosBucket.TodosTodosBucket>( arrayEntries.values(), Principal.compare );
                };
                case (#todosUsersDataBucket) {
                    let arrayEntries = Array.map(principals, func(principal) = (principal, actor(Principal.toText(principal)) : TodosUsersDataBucket.TodosUsersDataBucket));
                    memoryBucketsUsersData := Map.fromIter<Principal, TodosUsersDataBucket.TodosUsersDataBucket>( arrayEntries.values(), Principal.compare );
                };
                case (#todosGroupsBucket) {
                    let arrayEntries = Array.map(principals, func(principal) = (principal, actor(Principal.toText(principal)) : TodosGroupsBucket.TodosGroupsBucket));
                    memoryBucketsGroups := Map.fromIter<Principal, TodosGroupsBucket.TodosGroupsBucket>( arrayEntries.values(), Principal.compare );
                };
                case (#todosListsBucket) {
                    let arrayEntries = Array.map(principals, func(principal) = (principal, actor(Principal.toText(principal)) : TodosListsBucket.TodosListsBucket));
                    memoryBucketsLists := Map.fromIter<Principal, TodosListsBucket.TodosListsBucket>( arrayEntries.values(), Principal.compare );
                };
            };
        };

        setGlobalTimer(Nat64.fromIntWrap(Time.now()) + TIMER_INTERVAL_NS);
    };

    public shared ({ caller }) func setCoordinator(principal: Principal) : async () {
        if (caller != owner) { Runtime.trap( ERR_NOT_CONNECTED ); };
        
        coordinator := actor(Principal.toText(principal)) : Interfaces.Coordinator;
    };

    //
    // HELPERS
    //

    func requestNewFreeBucket(bucketType : CanistersKinds.BucketTodoKind) : async () {
        let principal = await coordinator.handlerGetFreeBucket( { nature = #todos(bucketType) } );

        switch (bucketType) {
            case (#todosTodosBucket)        currentTodosBucket := actor(Principal.toText(principal)) : TodosTodosBucket.TodosTodosBucket;
            case (#todosUsersDataBucket)    currentUsersDataBucket := actor(Principal.toText(principal)) : TodosUsersDataBucket.TodosUsersDataBucket;
            case (#todosGroupsBucket)       currentGroupsBucket := actor(Principal.toText(principal)) : TodosGroupsBucket.TodosGroupsBucket;
            case (#todosListsBucket)        currentListsBucket := actor(Principal.toText(principal)) : TodosListsBucket.TodosListsBucket;
        }; 
    };

    ///////////
    // USERS //
    ///////////

    type GetUserData = {
        todos: [TodoModel.Todo];
        todoLists: [TodoListModel.TodoList];
        groups: [GroupModel.Group];
    };

    // TODO: how can we dispatch and retrieve the users on buckets, the system cannot work like other buckets because we can't index each user wit the right bucket without exploding stable memory.
    // public shared ({ caller }) func getUserData() : async Result.Result<GetUserData, [Text]> {
    //     if (caller == Principal.anonymous()) { return #err([ERR_NOT_CONNECTED]); };

    //     switch ( await (currentUsersDataBucket.handlerGetUserData()) ) {
    //         case (#ok({ todos = todos; todoLists = todoLists; groups = groups })) #ok({ todos = todos; todoLists = todoLists; groups = groups });
    //         case (#err(e)) #err(e);
    //     }
    // };

    ///////////
    // TODOS //
    ///////////

    public shared ({ caller }) func createTodo(todo: TodoModel.Todo) : async Result.Result<Identifiers.WithID, [Text]> {
        if (caller == Principal.anonymous()) { return #err([ERR_NOT_CONNECTED]); };

        if ( Principal.fromActor(currentTodosBucket) == owner ) { await requestNewFreeBucket(#todosTodosBucket) };

        switch ( await (currentTodosBucket.handlerCreateTodo({ initialCaller = caller; todo = todo }) ) ) {
            case (#ok({ identifier = identifier; isFull = isFull })) {
                if (isFull) { ignore requestNewFreeBucket (#todosTodosBucket); };

                return #ok(identifier);
            };
            case (#err(e)) #err(e);
        }
    };

    public shared ({ caller }) func updateTodo(todo: TodoModel.Todo) : async Result.Result<(), [Text]> {
        if (caller == Principal.anonymous()) { return #err([ERR_NOT_CONNECTED]); };

        // TODO: we need to check is the user has the right to update the todo, either with the group permissions or because he is the owner
        switch ( await (currentTodosBucket.updateTodo(todo)) ) {
            case (#ok) #ok;
            case (#err(e)) #err(e);
        }
    };

    public shared ({ caller }) func removeTodo(id: Nat) : async Result.Result<(), Text> {
        if (caller == Principal.anonymous()) { return #err(ERR_NOT_CONNECTED); };

        // TODO: we need to check is the user has the right to delete the todo, either with the group permissions or because he is the owner
        switch ( await (currentTodosBucket.removeTodo(id)) ) {
            case (#ok) #ok;
            case (#err(e)) #err(e);
        }
    };
}