import Text "mo:base/Text";
import Map "mo:core/Map";
import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Option "mo:base/Option";
import Nat "mo:core/Nat";
import BucketUsers "./buckets/bucketUsers";
import BucketGroups "./buckets/bucketGroups";
import Todo "./models/todo";
import TodoList "./models/todoList";

persistent actor {
    let NEW_BUCKET_NB_CYCLES = 1_000_000_000;
    let BUCKET_USERS_DATA_MAX_ENTRIES = 10_000;
    let BUCKET_GROUPS_DATA_MAX_ENTRIES = 10_000;

    //
    // BUCKETS
    //

    var bucketUsersData: {var bucket: ?BucketUsers.BucketUsers; var nbUsers: Nat} =  { var bucket = null; var nbUsers = 0; };    
    var bucketGroupData: {var bucket: ?BucketGroups.BucketGroups; var nbGroups: Nat} =  { var bucket = null; var nbGroups = 0; };

    //
    // MAPPINGS
    //

    var principalsOnBuckets = Map.empty<Principal, BucketUsers.BucketUsers>();
    var groupsOnBuckets     = Map.empty<Nat, BucketGroups.BucketGroups>();

    //
    // INC
    //

    var lastTodoId      = 0;
    var lastTodoListId  = 0;
    var lastGroupId     = 0;

    //
    // USER 
    //

    // call this function when a user connect, create the bucket for the user if it doesn't exist.
    public shared ({ caller }) func login() : async Result.Result<(), Text> {
        if ( Principal.isAnonymous(caller) ) { return #err("Not logged in"); };

        if (Option.isSome( Map.get(principalsOnBuckets, Principal.compare, caller) )) { return #ok; };

        if ( Option.isNull(bucketUsersData.bucket)  or bucketUsersData.nbUsers >= BUCKET_USERS_DATA_MAX_ENTRIES ) { // create a new bucket
            let bucket = await BucketUsers.BucketUsers({ _cycles = NEW_BUCKET_NB_CYCLES });
            bucketUsersData.bucket := ?bucket;
        };

        let ?bucket = bucketUsersData.bucket else return #err("No bucket");
        Map.add( principalsOnBuckets, Principal.compare, caller, bucket );

        switch ( await bucket.createUserData(caller) ) {
            case (#ok) {
                bucketUsersData.nbUsers := bucketUsersData.nbUsers + 1; 
                #ok
            };
            case (#err err) #err(err);
        }
    };

    public shared ({ caller }) func getuserData() : async Result.Result<{todos: [Todo.Todo]; todoLists: [TodoList.TodoList]}, Text> {
        if ( Principal.isAnonymous(caller) ) { return #err("Not logged in"); };

        let ?bucket = Map.get(principalsOnBuckets, Principal.compare, caller) else return #err("No bucket");

        switch ( await bucket.getUserData(caller) ) {
            case (#ok data) #ok(data);
            case (#err err) #err(err);
        }
    };

    //
    // TODO
    //

    public shared ({ caller }) func createTodo(userPrincipal: Principal, todo: Todo.Todo) : async Result.Result<Nat, [Text]> {
        if ( Principal.isAnonymous(caller) ) { return #err(["Not logged in"]); };

        switch ( Todo.validateTodo(todo) ) { case (#ok) (); case (#err err) return #err(err); };

        let todoWithId = { todo with id = lastTodoId + 1; };

        let ?bucket = Map.get(principalsOnBuckets, Principal.compare, userPrincipal) else return #err(["No bucket"]);

        switch ( await bucket.createTodo(userPrincipal, todoWithId) ) {
            case (#ok) {
                lastTodoId := lastTodoId + 1;
                #ok(todoWithId.id)
            };
            case (#err err) #err(err);
        }
    };

    public shared ({ caller }) func updateTodo(userPrincipal: Principal, todo: Todo.Todo) : async Result.Result<(), [Text]> {
        if ( Principal.isAnonymous(caller) ) { return #err(["Not logged in"]); };

        switch ( Todo.validateTodo(todo) ) { case (#ok) (); case (#err err) return #err(err); };

        let ?bucket = Map.get(principalsOnBuckets, Principal.compare, userPrincipal) else return #err(["No bucket"]);

        switch ( await bucket.updateTodo(userPrincipal, todo) ) {
            case (#ok) #ok;
            case (#err err) #err(err);
        }
    };

    public shared ({ caller }) func removeTodo(userPrincipal: Principal, todoId: Nat) : async Result.Result<(), [Text]> {
        if ( Principal.isAnonymous(caller) ) { return #err(["Not logged in"]); };

        let ?bucket = Map.get(principalsOnBuckets, Principal.compare, userPrincipal) else return #err(["No bucket"]);

        switch ( await bucket.removeTodo(userPrincipal, todoId) ) {
            case (#ok) #ok;
            case (#err err) #err(err);
        }
    };

    //
    // TODO LIST
    //

    public shared ({ caller }) func createTodoList(userPrincipal: Principal, todoList: TodoList.TodoList) : async Result.Result<(), [Text]> {
        if ( Principal.isAnonymous(caller) ) { return #err(["Not logged in"]); };

        switch ( TodoList.validateTodoList(todoList) ) { case (#ok) (); case (#err err) return #err(err); };

        let todoListWithId = { todoList with id = lastTodoListId + 1; };

        let ?bucket = Map.get(principalsOnBuckets, Principal.compare, userPrincipal) else return #err(["No bucket"]);

        switch ( await bucket.createTodoList(userPrincipal, todoListWithId) ) {
            case (#ok) #ok;
            case (#err err) #err(err);
        }
    };

    public shared ({ caller }) func updateTodoList(userPrincipal: Principal, todoList: TodoList.TodoList) : async Result.Result<(), [Text]> {
        if ( Principal.isAnonymous(caller) ) { return #err(["Not logged in"]); };

        switch ( TodoList.validateTodoList(todoList) ) { case (#ok) (); case (#err err) return #err(err); };

        let ?bucket = Map.get(principalsOnBuckets, Principal.compare, userPrincipal) else return #err(["No bucket"]);

        switch ( await bucket.updateTodoList(userPrincipal, todoList) ) {
            case (#ok) #ok;
            case (#err err) #err(err);
        }
    };

    public shared ({ caller }) func removeTodoList(userPrincipal: Principal, todoListId: Nat) : async Result.Result<(), [Text]> {
        if ( Principal.isAnonymous(caller) ) { return #err(["Not logged in"]); };

        let ?bucket = Map.get(principalsOnBuckets, Principal.compare, userPrincipal) else return #err(["No bucket"]);

        switch ( await bucket.removeTodoList(userPrincipal, todoListId) ) {
            case (#ok) #ok;
            case (#err err) #err(err);
        }
    };

    //
    // GROUPS
    //

    func getOrCreateCurrentGroupBucket() : async ?BucketGroups.BucketGroups {
        if ( Option.isNull(bucketGroupData.bucket) or bucketGroupData.nbGroups > BUCKET_GROUPS_DATA_MAX_ENTRIES ) {
            let newBucket = await BucketGroups.BucketGroups({ _cycles = NEW_BUCKET_NB_CYCLES });
            bucketGroupData.bucket := ?newBucket;
        };

        return bucketGroupData.bucket
    };

    public shared ({ caller }) func createGroup(groupName: Text) : async Result.Result<Nat, [Text]> {
        if ( Principal.isAnonymous(caller) ) { return #err(["Not logged in"]); };

        let ?userBucket = Map.get(principalsOnBuckets, Principal.compare, caller) else return #err(["No bucket for user"]);
        let ?groupBucket = await getOrCreateCurrentGroupBucket() else return #err(["No bucket"]);
        
        // create the group
        switch ( await groupBucket.createGroupData( { adminPrincipal = caller; groupName = groupName; groupId = lastGroupId + 1; } ) ) {
            case (#ok) {
                lastGroupId := lastGroupId + 1;
                bucketGroupData.nbGroups := bucketGroupData.nbGroups + 1;
                Map.add(groupsOnBuckets, Nat.compare, lastGroupId, groupBucket);
            };
            case (#err err) return #err(err);
        };

        // add a link between the user and the group in userData
        switch ( await userBucket.addToGroup({ userPrincipal = caller; groupId = lastGroupId; }) ) {
            case (#ok) #ok(lastGroupId);
            case (#err err) #err(err);
        }
    }
};

