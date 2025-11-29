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

    var currentUsersDataBucket = actor(Principal.toText(owner)) : TodosUsersDataBucket.TodosUsersDataBucket;
    var currentGroupsBucket = actor(Principal.toText(owner)) : TodosMainBucket.TodosMainBucket;

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

    system func timer(setGlobalTimer : (Nat64) -> ()) : async () {
        // handling retry for errors
        let newErrors = List.empty<ErrorInterCanisterCall>();
        for ( (i, error) in List.enumerate(listAPIErrors)) {
            switch error {
                case (#errorCannotFetchNewBucket(bucketType)) {
                    switch ( await setNewCurrentBucket(bucketType) ) {
                        case (#ok) ();
                        case (#err(_)) List.add(newErrors, error);
                    };
                };
            };
        };

        listAPIErrors := newErrors;

        // reset timer
        setGlobalTimer(Nat64.fromIntWrap(Time.now()) + TIMER_INTERVAL_NS);
    };

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
    public shared func createNewUser() : async Result.Result<{ userBucket: Principal; groupBucket: Principal }, Text> {
        // 1) find right user buckets
        // 2) create a new entry in a groups bucket
        // 3) return the buckets principal for both uses buckets

        // TODO
        

        #err("not done")
    };

    ////////////
    // GROUPS //
    ////////////

    /////////////
    // HELPERS //
    /////////////

    func setNewCurrentBucket(bucketType: CanistersKinds.BucketTodoKind) : async Result.Result<(), Text> {
        try {
            let principal = await coordinatorActor.handlerGiveFreeBucket({ bucketKind = #todos(bucketType) });

            switch bucketType {
                case (#todosUsersDataBucket) currentUsersDataBucket := actor(Principal.toText(principal)) : TodosUsersDataBucket.TodosUsersDataBucket;
                case (#todosGroupsBucket) currentGroupsBucket := actor(Principal.toText(principal)) : TodosMainBucket.TodosMainBucket;
            };

            #ok
        } catch (e) {
            #err( "Error while fetching bucket: " # Error.message(e) )
        };
    };
}