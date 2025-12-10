import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Error "mo:core/Error";
import Runtime "mo:core/Runtime";
import CanistersMap "../../../shared/canistersMap";
import CanistersKinds "../../../shared/canistersKinds";
import TodosBucket "todosBucket";
import Interfaces "../../../shared/interfaces";

// only goal of this canister is too keep track of the relationship between users principals and canisters.
// this is the main piece of code which should need to change in case of scaling needs (by adding new users buckets )
shared ({ caller = owner }) persistent actor class TodosIndex() = this {
    ////////////
    // ERRORS //
    ////////////

    let ERR_CANNOT_FIND_CURRENT_BUCKET = "ERR_CANNOT_FIND_CURRENT_BUCKET";

    ////////////
    // MEMORY //
    ////////////

    let coordinatorActor = actor(Principal.toText(owner)) : Interfaces.Coordinator;

    let memoryCanisters = CanistersMap.newCanisterMap();

    var currentBucket: ?TodosBucket.TodosBucket = null;

    ////////////
    // SYSTEM //
    ////////////

    type InspectParams = {
        arg: Blob;
        caller : Principal;
        msg : {
            #systemAddCanisterToMap : () -> { canisterPrincipal: Principal; canisterKind: CanistersKinds.CanisterKind };

            #handlerAddUser : () -> ();
        };
    };

    system func inspect(params: InspectParams) : Bool {
        if ( params.caller == Principal.anonymous() ) { return false; };

        switch ( params.msg ) {
            case (#systemAddCanisterToMap(_)) params.caller == owner;
            case (#handlerAddUser(_)) true;
        }
    };

    public shared func systemAddCanisterToMap({ canisterPrincipal: Principal; canisterKind: CanistersKinds.CanisterKind }) : async () {
        CanistersMap.addCanisterToMap({ map = memoryCanisters; canisterPrincipal = canisterPrincipal; canisterKind = canisterKind });
    };

    /////////
    // API //
    /////////

    public shared ({ caller }) func handlerAddUser() : async Result.Result<Principal, Text> {
        // save user
        let ?bucket = await fetchCurrentUsersBucket() else return #err(ERR_CANNOT_FIND_CURRENT_BUCKET);

        switch ( await bucket.handlerCreateUser({ userPrincipal = caller }) ) {
            case (#ok(resp)) {
                if ( resp.isFull ) { currentBucket := null; };
                #ok(Principal.fromActor(bucket));
            };
            case (#err(e)) return #err(e);
        }
    };

    /////////////
    // HELPERS //
    /////////////

    func fetchCurrentUsersBucket() : async ?TodosBucket.TodosBucket {
        switch ( currentBucket ) {
            case (?_) ();
            case (null) {
                try {
                    let principal = await coordinatorActor.handlerGiveFreeBucket({ bucketKind = #todosBucket });
                    currentBucket := ?(actor(Principal.toText(principal)) : TodosBucket.TodosBucket);
                } catch (e) {
                    Runtime.trap( "Error while fetching bucket: " # Error.message(e) );
                };
            }
        };

        currentBucket
    };
};