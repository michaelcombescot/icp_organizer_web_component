import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Error "mo:core/Error";
import Runtime "mo:core/Runtime";
import CanistersMap "../../../shared/canistersMap";
import CanistersKinds "../../../shared/canistersKinds";
import TodosBucket "todosBucket";
import Interfaces "../../../shared/interfaces";
import UserData "../models/todosUserData";
import CanistersVirtualArray "../../../shared/canistersVirtualArray";

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

    var memoryUsersBuckets: CanistersVirtualArray.CanistersVirtualArray = [];

    var currentGroupBucket: ?TodosBucket.TodosBucket = null;

    ////////////
    // SYSTEM //
    ////////////

    type InspectParams = {
        arg: Blob;
        caller : Principal;
        msg : {
            #systemAddCanistersToMap : () -> { canistersPrincipals: [Principal]; canisterKind: CanistersKinds.CanisterKind };
            #systemUpdateUsersBucketsArray : () -> (principals: [Principal]);

            #handlerCreateUser : () -> ();
            #handlerGetUserData : () -> ();
        };
    };

    system func inspect(params: InspectParams) : Bool {
        if ( params.caller == Principal.anonymous() ) { return false; };

        switch ( params.msg ) {
            case (#systemAddCanistersToMap(_)) params.caller == owner;
            case (#systemUpdateUsersBucketsArray(_)) params.caller == owner;

            case (#handlerCreateUser(_)) true;
            case (#handlerGetUserData(_)) true;
        }
    };

    public shared func systemAddCanistersToMap({ canistersPrincipals: [Principal]; canisterKind: CanistersKinds.CanisterKind }) : async () {
        CanistersMap.addCanistersToMap({ map = memoryCanisters; canistersPrincipals = canistersPrincipals; canisterKind = canisterKind });
    };

    public shared func systemUpdateUsersBucketsArray(principals: [Principal]) : async () {
        memoryUsersBuckets := principals;
    };

    ///////////////
    // API USERS //
    ///////////////

    public shared ({ caller }) func handlerCreateUser() : async Result.Result<Principal, Text> {
        // save user
        let ?bucket = await fetchCurrentUsersBucket(caller) else return #err(ERR_CANNOT_FIND_CURRENT_BUCKET);

        switch ( await bucket.handlerCreateUser({ userPrincipal = caller }) ) {
            case (#ok(resp)) {
                if ( resp.isFull ) { currentGroupBucket := null; };
                #ok(Principal.fromActor(bucket));
            };
            case (#err(e)) return #err(e);
        }
    };

    public shared ({ caller }) func handlerGetUserData() : async Result.Result<UserData.SharableUserData, Text> {
        let ?bucket = await fetchCurrentUsersBucket(caller) else return #err(ERR_CANNOT_FIND_CURRENT_BUCKET);

        switch ( await bucket.handlerGetUserData({ userPrincipal = caller }) ) {
            case (#ok(resp)) #ok(resp);
            case (#err(e)) return #err(e);
        }
    };

    /////////////
    // HELPERS //
    /////////////

    func fetchCurrentUsersBucket(userPrincipal: Principal) : async ?TodosBucket.TodosBucket {
        let principal = await coordinatorActor.handlerGiveFreeBucket({ bucketKind = #todosBucket });
        ?(actor(Principal.toText(principal)) : TodosBucket.TodosBucket)
    };

    func fetchCurrentGroupBucket() : async ?TodosBucket.TodosBucket {
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