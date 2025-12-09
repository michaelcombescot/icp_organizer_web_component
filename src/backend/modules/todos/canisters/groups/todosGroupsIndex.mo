import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Text "mo:core/Text";
import Time "mo:core/Time";
import Map "mo:core/Map";
import Nat64 "mo:core/Nat64";
import List "mo:core/List";
import Blob "mo:core/Blob";
import Error "mo:core/Error";
import Runtime "mo:core/Runtime";
import CanistersKinds "../../../../shared/canistersKinds";
import Interfaces "../../../../shared/interfaces";
import CanistersMap "../../../../shared/canistersMap";
import TodosGroupsBucket "todosGroupsBucket";

// the goal of an index is to find or request the right bucket when we don't know beforehand which bucket to use, in the majority of cases to create a new object
shared ({ caller = owner }) persistent actor class TodosGroupsIndex() = this {
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

    let memoryCanisters = CanistersMap.newCanisterMap();

    var currentBucket: ?TodosGroupsBucket.TodosGroupsBucket = null;

    ////////////
    // SYSTEM //
    ////////////

    type Msg = {
        #systemAddCanisterToMap : () -> { canisterPrincipal: Principal; canisterKind: CanistersKinds.CanisterKind };

        #handlerCreateNewUser : () -> ();
    };

    system func inspect({ arg : Blob; caller : Principal; msg : Msg }) : Bool {
        if (Principal.isAnonymous(caller)) { return false; };

        // check per route
        switch msg {
            case (#systemUpdateCanistersMap(_)) return caller == owner;
            case (#handlerCreateNewUser(_)) return Blob.size(arg) <= 1000;
        }
    };

    // called only by the coordinator
    public shared func systemAddCanisterToMap({ canisterPrincipal: Principal; canisterKind: CanistersKinds.CanisterKind }) : async () {
        CanistersMap.addCanisterToMap({ map = memoryCanisters; canisterPrincipal = canisterPrincipal; canisterKind = canisterKind });
    };

    ///////////
    // USERS //
    ///////////

    // Create a new user.
    // a user is a group with a single associated principal.
    public shared ({ caller }) func handlerCreateNewUser() : async Result.Result<{ userBucket: Principal; groupBucket: Principal }, Text> {        
        let bucket = await fetchCurrentUsersBucket();

        #err("ERR_NOT_IMPLEMENTED");
    };

    ////////////
    // GROUPS //
    ////////////

    /////////////
    // HELPERS //
    /////////////

    func fetchCurrentUsersBucket() : async ?TodosGroupsBucket.TodosGroupsBucket {
        switch ( currentBucket ) {
            case (?_) ();
            case (null) {
                try {
                    let principal = await coordinatorActor.handlerGiveFreeBucket({ bucketKind = #todos(#todosUsersBucket) });
                    currentBucket := ?(actor(Principal.toText(principal)) : TodosGroupsBucket.TodosGroupsBucket);
                } catch (e) {
                    Runtime.trap( "Error while fetching bucket: " # Error.message(e) );
                };
            }
        };

        currentBucket
    };
};