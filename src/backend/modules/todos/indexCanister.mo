import Text "mo:base/Text";
import Map "mo:core/Map";
import Result "mo:core/Result";
import Principal "mo:base/Principal";
import Option "mo:base/Option";
import List "mo:core/List";
import Nat "mo:core/Nat";
import Array "mo:core/Array";
import BucketUsers "./buckets/bucketUsers";
import BucketGroups "./buckets/bucketGroups";
import Todo "./models/todo";
import TodoList "./models/todoList";
import User "models/user";
import Group "models/group";
import Helpers "../../helpers/helpers";
import Management "../../helpers/management";
import ExperimentalCycles "mo:base/ExperimentalCycles";

persistent actor {
    let NEW_BUCKET_NB_CYCLES = 1_000_000_000_000;
    let TOP_UP_AMOUNT = 1_000_000_000_000;
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

    var bucketsPrincipals   = List.empty<Principal>();
    var principalsOnBuckets = Map.empty<Principal, BucketUsers.BucketUsers>();
    var groupsOnBuckets     = Map.empty<Nat, BucketGroups.BucketGroups>();

    //
    // INC
    //

    var lastTodoId      = 0;
    var lastTodoListId  = 0;
    var lastGroupId     = 0;

    //
    // SYSTEM
    //

    system func heartbeat() : async () {
        for (bucketPrincipal in List.values(bucketsPrincipals)) {
            let status = await Management.canister_status({ canister_id = bucketPrincipal });
            if (status.cycles < threshold) {
                ExperimentalCycles.add<system>(amountToTopUp);
                await Management.deposit_cycles({ canister_id = bucketPrincipal });
            };
        };
    };

    //
    // USER 
    //

    // call this function when a user connect, create the bucket for the user if it doesn't exist.
    func getOrCreateUserBucket(caller: Principal) : async Result.Result<BucketUsers.BucketUsers, Text> {
        if ( Principal.isAnonymous(caller) ) { return #err("Not logged in"); };

        switch( Map.get(principalsOnBuckets, Principal.compare, caller) ) {
            case (?bucket) return #ok(bucket);
            case null ();
        };

        if ( Option.isNull(bucketUsersData.bucket)  or bucketUsersData.nbUsers >= BUCKET_USERS_DATA_MAX_ENTRIES ) { // create a new bucket
            let bucket = await (with cycles = NEW_BUCKET_NB_CYCLES) BucketUsers.BucketUsers();

            List.add(bucketsIds, Principal.fromActor(bucket));

            bucketUsersData.bucket := ?bucket;
        };

        let ?bucket = bucketUsersData.bucket else return #err("No bucket");
        Map.add( principalsOnBuckets, Principal.compare, caller, bucket );

        switch ( await bucket.createUserData(caller) ) {
            case (#ok) {
                bucketUsersData.nbUsers := bucketUsersData.nbUsers + 1; 
                #ok(bucket);
            };
            case (#err err) #err(err);
        }
    };

    public shared ({ caller }) func getuserData() : async Result.Result<User.GetUserDataResponse, [Text]> {
        if ( Principal.isAnonymous(caller) ) { return #err(["Not logged in"]); };

        let bucket = switch ( await getOrCreateUserBucket(caller) ) { case (#ok bucket) bucket; case (#err err) return #err([err]); };

        let userData = switch ( await bucket.getUserData(caller) ) {
            case (#ok data) data;
            case (#err err) return #err([err]);
        };

        // retrieve all groups data in //
        // 1 => construct of map of bucket => list of ids
        // 2 => for each bucket, launch the function to retrieve data
        // 3 => for each future, await and retrieve data
        let groupsIdsOnBucket = Map.empty<BucketGroups.BucketGroups, List.List<Nat>>();
        for ((groupId, _) in userData.groups.vals()) {
            switch (Map.get(groupsOnBuckets, Nat.compare, groupId)) {
                case (?bucket) {
                    let currentList = switch (Map.get(groupsIdsOnBucket, Helpers.compareBuckets, bucket)) {
                        case (?list) list;
                        case null   List.empty<Nat>();
                    };

                    List.add(currentList, groupId);
                    Map.add(groupsIdsOnBucket, Helpers.compareBuckets, bucket, currentList);
                };
                case null ();
            }
        };

        var futures = List.empty<async Result.Result<[(Nat, Group.GroupDataSharable)], [Text]>>();
        for ((bucket, idsList) in Map.entries(groupsIdsOnBucket) ) {
            let future = bucket.getGroupsData(List.toArray(idsList));
            List.add(futures, future);
        };

        let groupsData = List.empty<[(Nat, Group.GroupDataSharable)]>();
        for (future in List.values(futures)) {
            switch (await future) {
                case (#ok data) List.add(groupsData, data);
                case (#err err) return #err(err);
            }
        };

        let response = {
            todos = userData.todos;
            todoLists = userData.todoLists;
            groups = Array.flatten( List.toArray(groupsData) );
        };

        #ok(response);
    };

    //
    // TODO
    //

    public shared ({ caller }) func createTodo(todo: Todo.Todo) : async Result.Result<Nat, [Text]> {
        if ( Principal.isAnonymous(caller) ) { return #err(["Not logged in"]); };

        switch ( Todo.validateTodo(todo) ) { case (#ok) (); case (#err err) return #err(err); };

        let todoWithId = { todo with id = lastTodoId + 1; };

        let ?bucket = Map.get(principalsOnBuckets, Principal.compare, caller) else return #err(["No bucket"]);

        switch ( await bucket.createTodo(caller, todoWithId) ) {
            case (#ok) {
                lastTodoId := lastTodoId + 1;
                #ok(todoWithId.id)
            };
            case (#err err) #err(err);
        }
    };

    public shared ({ caller }) func updateTodo(todo: Todo.Todo) : async Result.Result<(), [Text]> {
        if ( Principal.isAnonymous(caller) ) { return #err(["Not logged in"]); };

        switch ( Todo.validateTodo(todo) ) { case (#ok) (); case (#err err) return #err(err); };

        let ?bucket = Map.get(principalsOnBuckets, Principal.compare, caller) else return #err(["No bucket"]);

        switch ( await bucket.updateTodo(caller, todo) ) {
            case (#ok) #ok;
            case (#err err) #err(err);
        }
    };

    public shared ({ caller }) func removeTodo(todoId: Nat) : async Result.Result<(), [Text]> {
        if ( Principal.isAnonymous(caller) ) { return #err(["Not logged in"]); };

        let ?bucket = Map.get(principalsOnBuckets, Principal.compare, caller) else return #err(["No bucket"]);

        switch ( await bucket.removeTodo(caller, todoId) ) {
            case (#ok) #ok;
            case (#err err) #err(err);
        }
    };

    //
    // TODO LIST
    //

    public shared ({ caller }) func createTodoList(todoList: TodoList.TodoList) : async Result.Result<(), [Text]> {
        if ( Principal.isAnonymous(caller) ) { return #err(["Not logged in"]); };

        switch ( TodoList.validateTodoList(todoList) ) { case (#ok) (); case (#err err) return #err(err); };

        let todoListWithId = { todoList with id = lastTodoListId + 1; };

        let ?bucket = Map.get(principalsOnBuckets, Principal.compare, caller) else return #err(["No bucket"]);

        switch ( await bucket.createTodoList(caller, todoListWithId) ) {
            case (#ok) #ok;
            case (#err err) #err(err);
        }
    };

    public shared ({ caller }) func updateTodoList(todoList: TodoList.TodoList) : async Result.Result<(), [Text]> {
        if ( Principal.isAnonymous(caller) ) { return #err(["Not logged in"]); };

        switch ( TodoList.validateTodoList(todoList) ) { case (#ok) (); case (#err err) return #err(err); };

        let ?bucket = Map.get(principalsOnBuckets, Principal.compare, caller) else return #err(["No bucket"]);

        switch ( await bucket.updateTodoList(caller, todoList) ) {
            case (#ok) #ok;
            case (#err err) #err(err);
        }
    };

    public shared ({ caller }) func removeTodoList(todoListId: Nat) : async Result.Result<(), [Text]> {
        if ( Principal.isAnonymous(caller) ) { return #err(["Not logged in"]); };

        let ?bucket = Map.get(principalsOnBuckets, Principal.compare, caller) else return #err(["No bucket"]);

        switch ( await bucket.removeTodoList(caller, todoListId) ) {
            case (#ok) #ok;
            case (#err err) #err(err);
        }
    };

    //
    // GROUPS
    //

    func getOrCreateCurrentGroupBucket() : async ?BucketGroups.BucketGroups {
        if ( Option.isNull(bucketGroupData.bucket) or bucketGroupData.nbGroups > BUCKET_GROUPS_DATA_MAX_ENTRIES ) {
            let newBucket = await (with cycles = NEW_BUCKET_NB_CYCLES) BucketGroups.BucketGroups();

            List.add(bucketsIds, Principal.fromActor(newBucket));

            bucketGroupData.bucket := ?newBucket;
        };

        return bucketGroupData.bucket
    };

    public shared ({ caller }) func createGroup(groupName: Text) : async Result.Result<Nat, [Text]> {
        if ( Principal.isAnonymous(caller) ) { return #err(["Not logged in"]); };

        let ?userBucket = Map.get(principalsOnBuckets, Principal.compare, caller) else return #err(["No bucket for user"]);
        let ?groupBucket = await getOrCreateCurrentGroupBucket() else return #err(["group bucket cannot be created"]);
        
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
    };    
};

