import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Error "mo:core/Error";
import Runtime "mo:core/Runtime";
import CanistersMap "../../../shared/canistersMap";
import CanistersKinds "../../../shared/canistersKinds";
import TodosBucket "todosBucket";
import Interfaces "../../../shared/interfaces";
import Identifiers "../../../shared/identifiers";
import Group "../models/todosGroup";

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

    var currentGroupBucket: ?TodosBucket.TodosBucket = null;

    ////////////
    // SYSTEM //
    ////////////

    type InspectParams = {
        arg: Blob;
        caller : Principal;
        msg : {
            #systemAddCanistersToMap : () -> { canistersPrincipals: [Principal]; canisterKind: CanistersKinds.CanisterKind };

            #handlerCreateGroup : () -> (params: Group.CreateGroupParams);
        };
    };

    system func inspect(params: InspectParams) : Bool {
        if ( params.caller == Principal.anonymous() ) { return false; };

        switch ( params.msg ) {
            case (#systemAddCanistersToMap(_)) params.caller == owner;

            case (#handlerCreateGroup(_)) true;
        }
    };

    public shared func systemAddCanistersToMap({ canistersPrincipals: [Principal]; canisterKind: CanistersKinds.CanisterKind }) : async () {
        CanistersMap.addCanistersToMap({ map = memoryCanisters; canistersPrincipals = canistersPrincipals; canisterKind = canisterKind });
    };

    ////////////////
    // API GROUPS //
    ////////////////

    public shared ({ caller }) func handlerCreateGroup(params: Group.CreateGroupParams) : async Result.Result<Identifiers.Identifier, Text> {
        let ?bucket = await helperFetchCurrentGroupBucket() else return #err(ERR_CANNOT_FIND_CURRENT_BUCKET);
    
        switch ( await bucket.handlerCreateGroup(caller, params) ) {
            case (#ok(resp)) {
                if ( resp.isFull ) { currentGroupBucket := null; };
                #ok(resp.identifier);
            };
            case (#err(e)) return #err(e);
        }
    };

    /////////////
    // HELPERS //
    /////////////

    func helperFetchCurrentGroupBucket() : async ?TodosBucket.TodosBucket {
        switch ( currentGroupBucket ) {
            case (?_) ();
            case (null) {
                try {
                    let principal = await coordinatorActor.handlerGiveFreeBucket({ bucketKind = #todosBucket });
                    currentGroupBucket := ?(actor(Principal.toText(principal)) : TodosBucket.TodosBucket);
                } catch (e) {
                    Runtime.trap( "Error while fetching bucket: " # Error.message(e) );
                };
            }
        };

        currentGroupBucket
    };
};