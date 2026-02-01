import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Error "mo:core/Error";
import Runtime "mo:core/Runtime";
import Debug "mo:core/Debug";
import GroupsBucket "../buckets/groupsBucket";
import TodosBucket "../buckets/todosBucket";
import UsersBucket "../buckets/usersBucket";
import UsersMapping "../../shared/usersMapping";
import Group "../todos/models/group";
import MixinOpsOperations "../../shared/mixins/mixinOpsOperations";
import MixinAllowedCanisters "../../shared/mixins/mixinAllowedCanisters";
import Timer "mo:core/Timer";

// only goal of this canister is too keep track of the relationship between users principals and canisters.
// this is the main piece of code which should need to change in case of scaling needs (by adding new users buckets )
shared ({ caller = owner }) persistent actor class TodoIndex() = this {
    /////////////
    // CONFIGS //
    /////////////

    ////////////
    // ERRORS //
    ////////////

    let ERR_CANNOT_FIND_CURRENT_GROUP_BUCKET = "ERR_CANNOT_FIND_CURRENT_GROUP_BUCKET";
    let ERR_USER_ALREADY_EXISTS = "ERR_USER_ALREADY_EXISTS";

    ////////////
    // MIXINS //
    ////////////

    include MixinOpsOperations({
        coordinatorPrincipal    = owner;
        canisterPrincipal       = Principal.fromActor(this);
        toppingThreshold        = 2_000_000_000_000;
        toppingAmount           = 2_000_000_000_000;
        toppingIntervalNs       = 60_000_000_000;
    });
    include MixinAllowedCanisters(coordinatorActor);    

    ////////////
    // MEMORY //
    ////////////

    var memoryUsersMapping: [Principal] = [];

    var currentGroupBucket: ?GroupsBucket.GroupsBucket = null;

    //////////
    // JOBS //
    //////////

    ignore Timer.setTimer<system>(
        #seconds(0),
        func () : async () {
            ignore Timer.recurringTimer<system>(#seconds(60_000_000_000), topCanisterRequest);
            await topCanisterRequest();
        }
    );

    ////////////
    // SYSTEM //
    ////////////

    type InspectParams = {
        
        arg: Blob;
        caller : Principal;
        msg : {
            #systemSetUserMapping : () -> (mapping: [Principal]);

            #handlerFetchOrCreateUser : () -> ();

            #handlerCreateGroup : () -> (params: Group.CreateGroupParams);
        };
    };

    system func inspect(params: InspectParams) : Bool {
        if ( params.caller == Principal.anonymous() ) { return false; };

        switch ( params.msg ) {
            case (#systemSetUserMapping(_)) params.caller == owner;

            case (#handlerFetchOrCreateUser(_)) true;

            case (#handlerCreateGroup(_)) not Principal.isAnonymous(params.caller);
        }
    };

    public shared func systemSetUserMapping(mapping: [Principal]) : async () {
        memoryUsersMapping := mapping;
        Debug.print("set users mapping for canister" # Principal.toText(Principal.fromActor(this)))
    };

    ///////////////
    // API USERS //
    ///////////////

    public shared ({ caller }) func handlerFetchOrCreateUser() : async Result.Result<Principal, Text> {
        let bucketPrincipal = UsersMapping.helperFetchUserBucket(memoryUsersMapping, caller);

        switch ( await (actor(Principal.toText(bucketPrincipal)): UsersBucket.UsersBucket).handlerCreateUser({ userPrincipal = caller }) ) {
            case (#ok()) #ok(bucketPrincipal);
            case (#err(e)) if ( e == ERR_USER_ALREADY_EXISTS) { #ok(bucketPrincipal) } else { #err(e) };
        }
    };

    ////////////////
    // API GROUPS //
    ////////////////

    public shared ({ caller }) func handlerCreateGroup(params: Group.CreateGroupParams) : async Result.Result<Identifiers.Identifier, Text> {
        let ?bucket = await helperFetchCurrentGroupBucket() else return #err(ERR_CANNOT_FIND_CURRENT_GROUP_BUCKET);
        let userBucket = UsersMapping.helperFetchUserBucket(memoryUsersMapping, caller);

        switch ( await bucket.handlerCreateGroup(caller, userBucket, params) ) {
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

    func helperFetchCurrentGroupBucket() : async ?GroupsBucket.GroupsBucket {
        switch ( currentGroupBucket ) {
            case (?_) ();
            case (null) {
                try {
                    let principal = switch (await coordinatorActor.handlerCreateBucket(#groupsBucket)) {
                        case (#ok(principal)) principal;
                        case (#err(e)) Runtime.trap( "[mainIndex] Error reponse when creating bucket: " # e );
                    };
                    currentGroupBucket := ?(actor(Principal.toText(principal)) : GroupsBucket.GroupsBucket);
                } catch (e) {
                    Runtime.trap( "[mainIndex] Error while fetching bucket: " # Error.message(e) );
                };
            }
        };

        currentGroupBucket
    };
};