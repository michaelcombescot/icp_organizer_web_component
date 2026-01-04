import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Error "mo:core/Error";
import Runtime "mo:core/Runtime";
import Debug "mo:core/Debug";
import GroupsBucket "groupsBucket";
import UsersBucket "usersBucket";
import Identifiers "../shared/identifiers";
import Group "../models/todosGroup";
import UsersMapping "../shared/usersMapping";
import MixinAllowedCanisters "mixins/mixinAllowedCanisters";
import Errors "../shared/errors"

// only goal of this canister is too keep track of the relationship between users principals and canisters.
// this is the main piece of code which should need to change in case of scaling needs (by adding new users buckets )
shared ({ caller = owner }) persistent actor class MainIndex() = this {
    let thisPrincipal = Principal.fromActor(this);

    include MixinAllowedCanisters(owner);    

    ////////////
    // MEMORY //
    ////////////

    var memoryUsersMapping: [Principal] = [];

    var currentGroupBucket: ?GroupsBucket.GroupsBucket = null;

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

            case (#handlerCreateGroup(_)) true;
        }
    };

    public shared func systemSetUserMapping(mapping: [Principal]) : async () {
        memoryUsersMapping := mapping;
        Debug.print("set users mapping for canister" # Principal.toText(thisPrincipal))
    };

    ///////////////
    // API USERS //
    ///////////////

    public shared ({ caller }) func handlerFetchOrCreateUser() : async Result.Result<Principal, Text> {
        let bucketPrincipal = UsersMapping.helperFetchUserBucket(memoryUsersMapping, caller);

        switch ( await (actor(Principal.toText(bucketPrincipal)): UsersBucket.UsersBucket).handlerCreateUser({ userPrincipal = caller }) ) {
            case (#ok()) #ok(bucketPrincipal);
            case (#err(e)) if ( e == Errors.ERR_USER_ALREADY_EXISTS) { #ok(bucketPrincipal) } else { #err(e) };
        }
    };

    ////////////////
    // API GROUPS //
    ////////////////

    public shared ({ caller }) func handlerCreateGroup(params: Group.CreateGroupParams) : async Result.Result<Identifiers.Identifier, Text> {
        let ?bucket = await helperFetchCurrentGroupBucket() else return #err(Errors.ERR_CANNOT_FIND_CURRENT_GROUP_BUCKET);
    
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

    func helperFetchCurrentGroupBucket() : async ?GroupsBucket.GroupsBucket {
        switch ( currentGroupBucket ) {
            case (?_) ();
            case (null) {
                try {
                    let principal = await coordinatorActor.handlerGiveNewBucket({ bucketKind = #groupsBucket });
                    currentGroupBucket := ?(actor(Principal.toText(principal)) : GroupsBucket.GroupsBucket);
                } catch (e) {
                    Runtime.trap( "Error while fetching bucket: " # Error.message(e) );
                };
            }
        };

        currentGroupBucket
    };
};