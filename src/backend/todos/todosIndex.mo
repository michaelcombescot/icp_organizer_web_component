import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Text "mo:core/Text";
import Time "mo:core/Time";
import Map "mo:core/Map";
import Nat64 "mo:core/Nat64";
import List "mo:core/List";
import Blob "mo:core/Blob";
import Error "mo:core/Error";
import TodosUsersDataBucket "buckets/todosUsersDataBucket";
import TodosMainBucket "buckets/todosMainBucket";
import CanistersKinds "../ops/canistersKinds";
import Interfaces "../shared/interfaces";

shared ({ caller = owner }) persistent actor class TodosIndex() = this {
    ////////////
    // CONFIG //
    ////////////

    let TIMER_INTERVAL_NS: Nat64 = 60_000_000_000;

    ////////////
    // ERRORS //
    ////////////

    let ERR_CANNOT_FETCH_NEW_BUCKET = "ERR_CANNOT_FETCH_NEW_BUCKET";

    type ErrorInterCanisterCall = {
        #errorCannotFetchNewBucket: CanistersKinds.BucketTodoKind;
    };

    var listAPIErrors = List.empty<ErrorInterCanisterCall>();

    ////////////
    // MEMORY //
    ////////////

    let coordinatorActor = actor(Principal.toText(owner)) : Interfaces.Coordinator;

    let memoryBucketsUsersData = Map.empty<Principal, TodosUsersDataBucket.TodosUsersDataBucket>();
    let memoryBucketsGroups = Map.empty<Principal, TodosMainBucket.TodosMainBucket>();

    var currentUsersDataBucket: ?TodosUsersDataBucket.TodosUsersDataBucket = null;
    var currentMainBucket: ?TodosMainBucket.TodosMainBucket = null;

    ////////////
    // SYSTEM //
    ////////////

    type Msg = {
        #systemAddBucket : () -> { bucketKind: CanistersKinds.BucketTodoKind; bucketPrincipal: Principal };

        #createNewUser : () -> ();
    };

    system func inspect({ arg : Blob; caller : Principal; msg : Msg }) : Bool {
        if (Principal.isAnonymous(caller)) { return false; };

        // check per route
        switch msg {
            case (#systemAddBucket(_)) return caller == owner;
            case (#createNewUser(_)) return Blob.size(arg) > 1000;
        }
    };

    // called only by the coordinator
    public shared func systemAddBucket({ bucketKind : CanistersKinds.BucketTodoKind; bucketPrincipal : Principal }) : async () {
        switch (bucketKind) {
            case (#todosUsersDataBucket) Map.add(memoryBucketsUsersData, Principal.compare, bucketPrincipal, actor(Principal.toText(bucketPrincipal)) : TodosUsersDataBucket.TodosUsersDataBucket);
            case (#todosGroupsBucket) Map.add(memoryBucketsGroups, Principal.compare, bucketPrincipal, actor(Principal.toText(bucketPrincipal)) : TodosMainBucket.TodosMainBucket);
        };
    };

    ///////////
    // USERS //
    ///////////

    // Create a new user.
    // a user is a group with a single associated principal.
    public shared ({ caller }) func createNewUser() : async Result.Result<{ userBucket: Principal; groupBucket: Principal }, Text> {
        // get user and main buckets in //
        let mainBucketPromise = fetchCurrentMainBucket();
        let userBucketPromise = fetchCurrentUserDataBucket();
        
        let mainBucket =    switch ( await mainBucketPromise ) {
                                case (#ok(bucket)) bucket;
                                case (#err(err)) return #err(err);
                            };

        let userBucket =    switch ( await userBucketPromise ) {
                                case (#ok(bucket)) bucket;
                                case (#err(err)) return #err(err);
                            };

        // create group
        let groupIdentifier =   switch ( await mainBucket.handlerCreateNewUserGroup( { userPrincipal = caller }) ) {
                                    case (#ok(response)) {
                                        if ( response.isFull ) { currentMainBucket := null; };
                                        response.groupIdentifier
                                    };
                                    case (#err(err)) return #err(err);
                                };

        // add group to user
        switch ( await userBucket.createUser({ userPrincipal = caller; groupIdentifier = groupIdentifier }) ) {
            case (#ok) ();
            case (#err(err)) return #err(err);
        };
        

        #ok({ userBucket = currentUsersDataBucket; groupBucket = currentMainBucket; });
    };

    ////////////
    // GROUPS //
    ////////////

    /////////////
    // HELPERS //
    /////////////

    func fetchCurrentUserDataBucket() : async Result.Result<TodosUsersDataBucket.TodosUsersDataBucket, Text> {
        switch (currentUsersDataBucket) {
            case (?bucket) #ok(bucket);
            case null {
                try {
                    let principal = await coordinatorActor.handlerGiveFreeBucket({ bucketKind = #todos(#todosUsersDataBucket) });
                    let aktor = actor(Principal.toText(principal)) : TodosUsersDataBucket.TodosUsersDataBucket;
                    currentUsersDataBucket := ?aktor;
                    #ok( aktor );  
                } catch (e) {
                    currentUsersDataBucket := null;
                    #err( "Error while fetching bucket: " # Error.message(e) )
                };
            };
        }
    };
    

    func fetchCurrentMainBucket() : async Result.Result<TodosMainBucket.TodosMainBucket, Text> {
        switch (currentMainBucket) {
            case (?bucket) #ok(bucket);
            case null {
                try {
                    let principal = await coordinatorActor.handlerGiveFreeBucket({ bucketKind = #todos(#todosUsersDataBucket) });
                    let aktor = actor(Principal.toText(principal)) : TodosMainBucket.TodosMainBucket;
                    currentMainBucket := ?aktor;
                    #ok( aktor );  
                } catch (e) {
                    currentMainBucket := null;
                    #err( ERR_CANNOT_FETCH_NEW_BUCKET # ": " # Error.message(e) )
                };
            };
        }
    };
}