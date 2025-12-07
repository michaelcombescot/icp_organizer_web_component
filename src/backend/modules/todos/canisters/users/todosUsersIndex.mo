import Map "mo:core/Map";
import Principal "mo:core/Principal";
import Option "mo:core/Option";
import Result "mo:core/Result";
import Error "mo:core/Error";
import Runtime "mo:core/Runtime";
import Debug "mo:base/Debug";
import CanistersMap "../../../../shared/canistersMap";
import CanistersKinds "../../../../shared/canistersKinds";
import TodosUsersBucket "todosUsersBucket";
import Interfaces "../../../../shared/interfaces";

// only goal of this canister is too keep track of the relationship between users principals and canisters.
// this is the main piece of code which should need to change in case of scaling needs (by adding new users buckets )
shared ({ caller = owner }) persistent actor class TodosUsersIndex() = this {

    ////////////
    // MEMORY //
    ////////////

    let coordinatorActor = actor(Principal.toText(owner)) : Interfaces.Coordinator;

    var memoryCanisters = CanistersMap.arrayToCanistersMap([]);

    var currentBucket: ?TodosUsersBucket.TodosUsersBucket = null;

    ////////////
    // SYSTEM //
    ////////////

    type InspectParams = {
        arg: Blob;
        caller : Principal;
        msg : {
            #systemUpdateCanistersMap : () -> {canisters: [(CanistersKinds.CanisterKind, [Principal])]};

            #handlerAddUser : () -> ();
        };
    };

    system func inspect(params: InspectParams) : Bool {
        if ( params.caller == Principal.anonymous() ) { return false; };

        switch ( params.msg ) {
            case (#systemUpdateCanistersMap(_)) params.caller == owner;
            case (#handlerAddUser(_)) true;
        }
    };

    public shared func systemUpdateCanistersMap({ canisters: [(CanistersKinds.CanisterKind, [Principal])] }) : async () {
        memoryCanisters := CanistersMap.arrayToCanistersMap(canisters);
    };

    /////////
    // API //
    /////////

    public shared ({ caller }) func handlerAddUser() : async Result.Result<Principal, Text> {
        let bucket = await fetchCurrentUsersBucket();

        #err("ERR_NOT_IMPLEMENTED");
    };

    /////////////
    // HELPERS //
    /////////////

    func fetchCurrentUsersBucket() : async ?TodosUsersBucket.TodosUsersBucket {
        switch ( currentBucket ) {
            case (?_) ();
            case (null) {
                try {
                    let principal = await coordinatorActor.handlerGiveFreeBucket({ bucketKind = #todos(#todosUsersBucket) });
                    currentBucket := ?(actor(Principal.toText(principal)) : TodosUsersBucket.TodosUsersBucket);
                } catch (e) {
                    Runtime.trap( "Error while fetching bucket: " # Error.message(e) );
                };
            }
        };

        currentBucket
    };
};