import Map "mo:core/Map";
import Result "mo:core/Result";
import Principal "mo:core/Principal";
import List "mo:core/List";
import UserData "./userDataModel";
import Errors "../../shared/errors";

shared ({ caller = owner }) persistent actor class UsersDataBucket(indexPrincipal: Principal) = this {
    let ERR_USER_DATA_NOT_FOUND = "ERR_USER_DATA_NOT_FOUND";

    var index = indexPrincipal;
    var usersData = Map.empty<Principal, UserData.UserData>();

    //
    // API
    //

    // create user data
    public shared ({ caller }) func createUserData(userPrincipal: Principal) : async Result.Result<Nat, Text> {
        if ( caller != index ) { return #err(Errors.ERR_CAN_ONLY_BE_CALLED_BY_INDEX); };

        let ?_ = Map.get(usersData, Principal.compare, userPrincipal) else return #err(Errors.ERR_USER_DATA_ALREADY_EXISTS);

        Map.add(usersData, Principal.compare, userPrincipal, {
                todos = List.empty<Text>();
                todoLists = List.empty<Text>();
        });

        #ok(usersData.size)
    };

    // get user data 
    type GetUserDataResponse = {
        todos: [Text];
        todoLists: [Text];
    };

    public shared ({ caller }) func getuserData() : async Result.Result<GetUserDataResponse, Text> {
        let ?data =  Map.get(usersData, Principal.compare, caller) else return #err(ERR_USER_DATA_NOT_FOUND);

        #ok({
            todos = List.toArray(data.todos);
            todoLists = List.toArray(data.todoLists);
        })
    };   
};