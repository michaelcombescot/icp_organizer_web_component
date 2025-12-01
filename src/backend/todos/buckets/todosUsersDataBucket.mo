import Map "mo:core/Map";
import Principal "mo:core/Principal";
import List "mo:core/List";
import Blob "mo:core/Blob";
import Result "mo:core/Result";
import Time "mo:core/Time";
import UserDataModel "../models/todosUserDataModel";
import Identifier "../../shared/identifiers";

shared ({ caller = owner }) persistent actor class TodosUsersDataBucket() = this {
    ////////////
    // CONFIG //
    ////////////

    let CONFIG_MAX_NUMBER_ENTRIES = 10_000;

    ////////////
    // ERRORS //
    ////////////

    let ERR_BUCKET_FULL = "ERR_BUCKET_FULL";

    let ERR_USER_ALREADY_EXISTS = "ERR_USER_ALREADY_EXISTS";

    ////////////
    // STATES //
    ////////////

    var memoryIndexes        = List.empty<Principal>();

    let memoryUsersData      = Map.empty<Principal, UserDataModel.UserData>();

    ////////////
    // SYSTEM //
    ////////////

    type InspectParams = {
        arg: Blob;
        caller : Principal;
        msg : {
            #systemAddIndex: () -> { indexPrincipal : Principal};
            #createUser: () -> { userPrincipal : Principal };
        };
    };

    system func inspect(params: InspectParams) : Bool {
        if (Principal.isAnonymous(params.caller)) { return false; };

        if (Blob.size(params.arg) > 500) { return false; };

        switch ( params.msg ) {
            case (#systemAddIndex(_)) params.caller == owner;
            case (#createUser(_))     List.contains(memoryIndexes, Principal.equal, params.caller);
        }        
    };

    public shared func systemAddIndex({ indexPrincipal: Principal }) : async () {
        List.add(memoryIndexes, indexPrincipal);
    };

    /////////
    // API //
    /////////

    public shared func createUser({ userPrincipal: Principal; groupIdentifier : Identifier.Identifier }) : async Result.Result<(), Text> {
        if ( Map.size(memoryUsersData) >= CONFIG_MAX_NUMBER_ENTRIES ) { return #err(ERR_BUCKET_FULL); };

        let ?_ = Map.get(memoryUsersData, Principal.compare, userPrincipal) else return #err(ERR_USER_ALREADY_EXISTS);

        let userData : UserDataModel.UserData = {
            groups = Map.singleton<Identifier.Identifier, ()>( (groupIdentifier, ()) );
            createdAt = Time.now();
        };
        
        Map.add(memoryUsersData, Principal.compare, userPrincipal, userData);

        #ok
    };
};