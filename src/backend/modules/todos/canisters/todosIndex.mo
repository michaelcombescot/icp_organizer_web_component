import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Error "mo:core/Error";
import Runtime "mo:core/Runtime";
import List "mo:core/List";
import Nat64 "mo:core/Nat64";
import Time "mo:core/Time";
import Debug "mo:core/Debug";
import CanistersMap "../../../shared/canistersMap";
import CanistersKinds "../../../shared/canistersKinds";
import TodosGroupsBucket "todosGroupsBucket";
import Interfaces "../../../shared/interfaces";
import CanistersVirtualArray "../../../shared/canistersVirtualArray";
import Identifiers "../../../shared/identifiers";
import Group "../models/todosGroup";
import TodosUsersBucket "todosUsersBucket";

// only goal of this canister is too keep track of the relationship between users principals and canisters.
// this is the main piece of code which should need to change in case of scaling needs (by adding new users buckets )
shared ({ caller = owner }) persistent actor class TodosIndex() = this {
    ////////////
    // ERRORS //
    ////////////

    let TIMER_INTERVAL_NS = 20_000_000_000;

    let ERR_CANNOT_FIND_CURRENT_BUCKET = "ERR_CANNOT_FIND_CURRENT_BUCKET";
    let ERR_CANNOT_CREATE_GROUP = "ERR_CANNOT_CREATE_GROUP";
    let ERR_CANNOT_CREATE_USER = "ERR_CANNOT_CREATE_USER";

    type ErrTypes = {
        #errCannotCreateUserMusrDeleteGroup: { groupIdentifier: Identifiers.Identifier };
    };

    var errList = List.empty<ErrTypes>();

    ////////////
    // MEMORY //
    ////////////

    let coordinatorActor = actor(Principal.toText(owner)) : Interfaces.Coordinator;

    let memoryCanisters = CanistersMap.newCanisterMap();

    var memoryUsersBuckets: CanistersVirtualArray.CanistersVirtualArray = [];

    var currentGroupBucket: ?TodosGroupsBucket.TodosGroupsBucket = null;

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
            #handlerCreateGroup : () -> (params: Group.CreateGroupParams);
        };
    };

    system func inspect(params: InspectParams) : Bool {
        if ( params.caller == Principal.anonymous() ) { return false; };

        switch ( params.msg ) {
            case (#systemAddCanistersToMap(_)) params.caller == owner;
            case (#systemUpdateUsersBucketsArray(_)) params.caller == owner;

            case (#handlerCreateUser(_)) true;
            case (#handlerCreateGroup(_)) true;
        }
    };

    system func timer(setGlobalTimer : (Nat64) -> ()) : async () {
        setGlobalTimer(Nat64.fromIntWrap(Time.now()) + Nat64.fromNat(TIMER_INTERVAL_NS));

        await helperHandleErrors();
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

    public shared ({ caller }) func handlerCreateUser() : async Result.Result<{ bucketUser: Principal; groupIdentifier: Identifiers.Identifier }, Text> {
        // create group
        let ?bucketGroup = await helperFetchCurrentGroupBucket() else return #err(ERR_CANNOT_FIND_CURRENT_BUCKET);

        let groupCreationCall = try { await bucketGroup.handlerCreateGroup(caller, { name = "My Group"; kind = #personnal }); }
                                catch (e) {
                                    Debug.print("Error while creating group: " # Error.message(e));
                                    return #err(ERR_CANNOT_CREATE_GROUP); 
                                };

        let groupIdentifier =   switch ( groupCreationCall ) {
                                    case (#ok(resp)) {
                                        if ( resp.isFull ) { currentGroupBucket := null; };
                                        resp.identifier
                                    };
                                    case (#err(e)) return #err(e);
                                };

        // create user
        let bucketUser = helperFetchUserBucket(caller);

        let userCreationCall = try { await bucketUser.handlerCreateUser({ userPrincipal = caller; groupIdentifier = groupIdentifier }) }
                                catch (e) {
                                    Debug.print("Error while creating user: " # Error.message(e));
                                    List.add(errList, #errCannotCreateUserMusrDeleteGroup({ groupIdentifier = groupIdentifier }));
                                    return #err(ERR_CANNOT_CREATE_USER); 
                                };
            
        switch ( userCreationCall ) {
            case (#ok(_))    #ok({ bucketUser = Principal.fromActor(bucketUser); groupIdentifier = groupIdentifier });
            case (#err(e)) {
                List.add(errList, #errCannotCreateUserMusrDeleteGroup({ groupIdentifier = groupIdentifier }));
                #err(e);
            };
        }
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

    func helperFetchCurrentGroupBucket() : async ?TodosGroupsBucket.TodosGroupsBucket {
        switch ( currentGroupBucket ) {
            case (?_) ();
            case (null) {
                try {
                    let principal = await coordinatorActor.handlerGiveFreeBucket({ bucketKind = #todosGroupsBucket });
                    currentGroupBucket := ?(actor(Principal.toText(principal)) : TodosGroupsBucket.TodosGroupsBucket);
                } catch (e) {
                    Runtime.trap( "Error while fetching bucket: " # Error.message(e) );
                };
            }
        };

        currentGroupBucket
    };

    func helperFetchUserBucket(userPrincipal: Principal) : TodosUsersBucket.TodosUsersBucket {
        let principal = CanistersVirtualArray.fetchUserBucket(memoryUsersBuckets, userPrincipal);
        actor(Principal.toText(principal)) : TodosUsersBucket.TodosUsersBucket
    };

    func helperHandleErrors() : async () {
        // handle errors
        let newList = List.empty<ErrTypes>();
        for ( err in List.values(errList) ) {
            switch ( err ) {
                case (#errCannotCreateUserMusrDeleteGroup(params)) {
                    let aktor = actor(Principal.toText(params.groupIdentifier.bucket)) : TodosGroupsBucket.TodosGroupsBucket;
                    try {
                        switch ( await aktor.handlerDeleteGroup(params.groupIdentifier.id) ) {
                            case (#ok()) ();
                            case (#err(e)) {
                                Debug.print("Error while deleting group: " # e);
                                List.add(newList, err);
                            };
                        };
                    } catch (e) {
                        Debug.print("Error while deleting group: " # Error.message(e));
                        List.add(newList, err); 
                    };
                };
            };
        };

        errList := newList;
    };
};